unit qrbtree;

interface

{.$DEFINE PRINT_TREE }
{
  本单元红黑树改编自Linux 3.14.4内核红黑树实现，基本上是照抄，但我不保证抄袭就100%
  正确:)。有觉得不对的时候，可以找linux内核的rbtree.h/rbtree_augmented.h/rbtree.c
  对照看看是否一不小心抄漏了。
  下面是GPL协议的原文，按照规定放到本部分：
  /*
  Red Black Trees
  (C) 1999  Andrea Arcangeli <andrea@suse.de>
  (C) 2002  David Woodhouse <dwmw2@infradead.org>
  (C) 2012  Michel Lespinasse <walken@google.com>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  linux/lib/rbtree.c
  */
  顺便说一句，如果您发现有问题，顺便发个信息提醒我一下：
  QDAC官网：www.qdac.cc
  QDAC官方群：250530692
  QQ邮箱:109867294@qq.com
}
{$I 'qdac.inc'}
{ .$DEFINE DEBUG_EXISTS }// Enable duplicate push test

uses
  Classes, sysutils, qstring{$IFDEF PRINT_TREE}, qlog, windows{$ENDIF};
{$HPPEMIT '#pragma link "qrbtree"'}

type
  /// <summary>比较函数，我还是决定加上 of object了，如果你觉得是个错误的决定，去掉它好了</summary>
  /// <param name='P1'>第一个要比较的参数</param>
  /// <param name='P2'>第二个要比较的参数</param>
  /// <returns>如果P1<P2，返回小于0的值，如果P1>P2返回大于0的值，如果相等，返回0</returns>
  TQRBCompare = function(P1, P2: Pointer): Integer of object;

  TQRBNode = class;
  PQRBNode = ^TQRBNode;
  TQRBTree = class;
  PQRBTree = ^TQRBTree;
  /// <summary>
  /// 删除结点通知事件，在删除一个树结点时触发
  /// </summary>
  /// <param name="ASender">触发事件的红黑树对象</param>
  /// <param name="ANode">要删除的结点</param>
  TQRBDeleteNotify = procedure(ASender: TQRBTree; ANode: TQRBNode) of object;
  // 下面三个事件我真没想到啥时需要，原Linux代码中触发了，我也就保留了
  TQRBRotateNotify = procedure(ASender: TQRBTree; AOld, ANew: TQRBNode)
    of object;
  TQRBCopyNotify = TQRBRotateNotify;
  TQRBPropagateNotify = procedure(ASender: TQRBTree; ANode, AStop: TQRBNode)
    of object;

  /// <summary>TQRBNode是一个红黑树结点记录，与Linux代码相比，增加了一个Data成员
  /// 来直接保存外部数据指针，原打算象VirtualTreeView一样设置一个DataSize，后来
  /// 觉得反正要分配两次内存，没多大区别就放弃了，当然，如果改成record的话，应该
  /// 能少一次内存分配，暂时先不做此优化，将来再说(record+record helper)。
  /// </summary>
  TQRBNode = class
  private
    FParent_Color: IntPtr;
    FLeft, FRight: TQRBNode;
    FData: Pointer;
    function GetNext: TQRBNode; inline;
    function GetParent: TQRBNode; inline;
    function GetPrior: TQRBNode; inline;
    function GetIsEmpty: Boolean; inline;
    procedure SetBlack; inline;
    function RedParent: TQRBNode; inline;
    procedure SetParentColor(AParent: TQRBNode; AColor: Integer); inline;
    function GetIsBlack: Boolean; inline;
    function GetIsRed: Boolean; inline;
    procedure SetParent(const Value: TQRBNode); inline;
    function GetLeftDeepest: TQRBNode; inline;
  public
    constructor Create; overload;
    destructor Destroy; override;
    /// <summary>
    /// 拷贝函数，复制相应的数据成员
    /// </summary>
    /// <param name="src">源结点</param>
    procedure Assign(src: TQRBNode);
    /// <summary>下一后根次序结点，我反正用不上，对应于rb_next_postorder函数</summary>
    function NextPostOrder: TQRBNode;
    /// <summary>重置为空结点，调用后IsEmpty将返回true</summary>
    procedure Clear;
    /// 下一结点
    property Next: TQRBNode read GetNext; // rb_next
    /// 前一结点
    property Prior: TQRBNode read GetPrior; // rb_prev
    /// 父结点
    property Parent: TQRBNode read GetParent write SetParent; // rb_parent
    /// 是否是空结点
    property IsEmpty: Boolean read GetIsEmpty; // RB_NODE_EMPTY
    /// 是否是黑结点
    property IsBlack: Boolean read GetIsBlack; // rb_is_black
    /// 是否为红结点
    property IsRed: Boolean read GetIsRed; // rb_is_red
    /// 右结点
    property Right: TQRBNode read FRight write FRight; // rb_right
    /// 左结点
    property Left: TQRBNode read FLeft write FLeft; // rb_left
    /// 附加数据成员
    property Data: Pointer read FData write FData; // 附加数据成员
    /// 最深的最左结点
    property LeftDeepest: TQRBNode read GetLeftDeepest;
  end;

  /// <summary>红黑树Delphi对象封装</summary>
  TQRBTree = class
  protected
    FRoot: TQRBNode;
    FCount: Integer;
    FOnCompare: TQRBCompare;
    FOnDelete: TQRBDeleteNotify;
    FOnRotate: TQRBRotateNotify;
    FOnCopy: TQRBCopyNotify;
    FOnPropagate: TQRBPropagateNotify;
    function GetIsEmpty: Boolean; inline;
    procedure RotateSetParents(AOld, ANew: TQRBNode; color: Integer); inline;
    procedure InsertNode(node: TQRBNode); inline;
    procedure EraseColor(AParent: TQRBNode); inline;
    procedure ChangeChild(AOld, ANew, Parent: TQRBNode); inline;
    function EraseAugmented(node: TQRBNode): TQRBNode; inline;
    procedure DoCopy(node1, node2: TQRBNode); inline;
    procedure DoPropagate(node1, node2: TQRBNode); inline;
    procedure InsertColor(AChild: TQRBNode); inline;
    procedure DoRotate(AOld, ANew: TQRBNode); inline;
    procedure LinkNode(node, Parent: TQRBNode; var rb_link: TQRBNode); inline;
{$IFDEF PRINT_TREE}
    procedure PrintTree(AHint: String);
{$ENDIF}
  public
    /// <summary>构造函数，传递一个大小比较函数进去，以便在插入和查找时能够正确的区分</summary>
    constructor Create(AOnCompare: TQRBCompare); overload;
    destructor Destroy; override;
    /// <summary>删除一个结点</summary>
    /// <param name="AChild">要删除的结点</param>
    /// <returns>成功，返回被删除结点的Data数据成员地址，失败或不存在，返回nil</returns>
    /// <remarks>如果你指定的OnDelete事件响应并释放了Data成员，就不要尝试访问返回的地址</remarks>
    function Delete(AChild: TQRBNode): Pointer; // rb_erase
    /// <summary>首个结点</summary>
    function First: TQRBNode; // rb_first
    /// <summary>首个结点</summary>
    function Last: TQRBNode; // rb_last
    /// <summary>首个后根次序结点</summary>
    function FirstPostOrder: TQRBNode; // rb_first_postorder
    /// <summary>插入一个数据，比较由构造时传入的事件回调函数处理</summary>
    /// <param name="AData">数据成员</param>
    /// <returns>成功，返回true，失败，返回false</returns>
    /// <remarks>如果指定的数据相同内容已经存在，就会返回false</remarks>
    function Insert(AData: Pointer): Boolean;
    /// <summary>查找与指定的数据内容相同的结点</summary>
    /// <param name="AData">要用于搜索的数据内容</param>
    /// <returns>返回找到的结点</returns>
    function Find(AData: Pointer): TQRBNode;
    /// <summary>清除所有的结点</summary>
    procedure Clear;
    /// <summary>替换结点</summary>
    /// <param name="victim">牺牲品，要被替换的结点</param>
    /// <param name="ANew">新结点</param>
    /// <remarks>替换要自己保证内容和牺牲品一致，否则可能造成树错乱，如果不能保证,
    /// 尝试删除+添加来完成替换
    /// </remarks>
    procedure Replace(victim, ANew: TQRBNode);
    /// 判断树是否为空树
    property IsEmpty: Boolean read GetIsEmpty;
    /// 比较函数，注意不要在树插入后更改比较算法
    property OnCompare: TQRBCompare read FOnCompare write FOnCompare;
    /// 删除事件响应函数
    property OnDelete: TQRBDeleteNotify read FOnDelete write FOnDelete;
    /// 旋转事件
    property OnRotate: TQRBRotateNotify read FOnRotate write FOnRotate;
    /// 复制事件
    property OnCopy: TQRBCopyNotify read FOnCopy write FOnCopy;
    /// 扩散事件
    property OnPropagate: TQRBPropagateNotify read FOnPropagate
      write FOnPropagate;
    // 结点数量
    property Count: Integer read FCount;
  end;

  /// 桶内元素的哈希值列表
  TQHashType = Cardinal;
  PQHashList = ^TQHashList;

  TQHashList = record
    Next: PQHashList;
    /// 下一元素
    Hash: TQHashType;
    /// 当前元素哈希值，记录以便重新分配桶时不需要再次外部计算
    Data: Pointer;
    /// 附加数据成员
  end;

  TQHashArray = array of PQHashList;
  TQHashTable = class;
  /// <summary>删除哈希表一个元素的通知</summary>
  /// <param name="ATable">哈希表对象</param>
  /// <param name="AHash">要删除的对象的哈希值</param>
  /// <param name="AData">要删除的对象数据指针</param>
  TQHashNotify = procedure(ATable: TQHashTable; AHash: TQHashType;
    AData: Pointer) of object;
  TQBucketNotify = procedure(ATable: TQHashTable; ABucketIndex: Integer)
    of object;

  TQHashStatics = record
    Count: Integer; // 有效的桶数
    MaxDepth: Integer; // 最大深度
    AvgDepth: Double; // 平均尝试
    TotalDepth: Integer; // 总深度
    MaxItems: PQHashList; // 最深列表
    DepthList: array of Integer; // 不同深度列表
  end;

  TQHashTableIterator = class
  protected
    FCurrent: PQHashList;
    FList: TQHashTable;
    FBucket: Integer;
  public
    constructor Create(AList: TQHashTable);
    function GetCurrent: PQHashList; inline;
    function MoveNext: Boolean;
    property Current: PQHashList read GetCurrent;
  end;

  {
    哈希表用于存贮一些用于查询的散列数据，哈希表的效率取决于合适的桶大小和合适
    的哈希函数，理想情况下的最佳效率是O(1)。
    1.添加
    调用Add函数添加一个元素进去，如果要防止重复添加先调用Find函数检查下。
    2.删除
    调用Delete函数完成删除
    3.查找
    查找是哈希表的最重要函数，查找之前请设置OnCompare函数，以便比较Data关联的内容
    的值，否则，系统将只比较Data指针的地址是否一致。
  }
  TQHashTable = class
  private
    procedure SetAutoSize(const Value: Boolean);
  protected
    FBuckets: TQHashArray;
    FCount: Integer;
    FOnDelete: TQHashNotify;
    FOnCompare: TQRBCompare;
    FAfterBucketUsed, FAfterBucketEmpty: TQBucketNotify;
    FAutoSize: Boolean;
    procedure DoDelete(AHash: TQHashType; AData: Pointer);
    function GetBuckets(AIndex: Integer): PQHashList; inline;
    function GetBucketCount: Integer; inline;
    function Compare(Data1, Data2: Pointer; var AResult: Integer)
      : Boolean; inline;
    procedure BuncketsNeeded; inline;
    procedure InternalDelete(AIndex: Integer; APrior, AHashList: PQHashList);
  public
    /// 构造函数，以桶数量为参数，后期可以调用Resize调整
    constructor Create(ASize: Integer); overload;
    /// 构造函数
    constructor Create; overload;
    destructor Destroy; override;
    /// <summary>调整桶数量</summary>
    /// <param name="ASize">新的桶数量，如果为0，则自动调整为最接近元素数量的值</param>
    procedure Resize(ASize: Cardinal);
    /// <summary>添加一个元素<summary>
    /// <param name="AData">要添加的元素地址</param>
    /// <param name="AHash">要添加元素的哈希值</param>
    /// <remarks>哈希值的计算由外部调用者负责完成，哈希表假定传进的哈希值是已经计算完成的</remarks>
    procedure Add(AData: Pointer; AHash: TQHashType);
    /// <summary> 查找指定的哈希值的元素列表</summary>
    /// <param name="AHash">要查找的哈希值</param>
    /// <returns>返回找到的哈希值列表，如果没有，返回nil</returns>
    /// <remarks>返回的哈希列表应调用FreeHashList来释放</remarks>
    function Find(AHash: TQHashType): PQHashList; overload;
    /// <summary> 查找指定的哈希值的元素列表</summary>
    /// <param name="AData">要查找的数据内容指针，它将被传给OnCompare来比较是否一致</param>
    /// <param name="AHash">要查找的哈希值</param>
    /// <returns>返回找到的附加数据地址，如果没有，返回nil</returns>
    function Find(AData: Pointer; AHash: TQHashType): Pointer; overload;
    /// <summary>查找指定哈希值的第一个元素值</summary>
    /// <param name="AHash">要查找的哈希值</param>
    /// <returns>返回找到的元素数据地址，如果没有，返回nil</returns>
    function FindFirstData(AHash: TQHashType): Pointer;
    /// <summary> 查找指定的哈希值的元素列表</summary>
    /// <param name="AHash">要查找的哈希值</param>
    /// <returns>返回找到的哈希值列表，如果没有，返回nil</returns>
    /// <remarks>不要释放返回的哈希列表对象首个元素，它返回的是内部列表找到的首个地址</remarks>
    function FindFirst(AHash: TQHashType): PQHashList; inline;
    /// <summary> 查找指定的哈希值的元素列表的下一个元素</summary>
    /// <param name="AList">FindFirst/FindNext返回的列表</param>
    /// <returns>返回哈希值列表下一个元素，如果没有，返回nil</returns>
    function FindNext(AList: PQHashList): PQHashList; inline;
    /// <summary> 释放哈希值元素列表</summary>
    /// <param name="AList">由Find返回的列表对象</param>
    procedure FreeHashList(AList: PQHashList);
    /// <summary>判断指定的元素是否存在</summary>
    /// <param name="AData">要判断的元素值指针地址</param>
    /// <param name="AHash">AData对应的哈希值</param>
    /// <returns>如果存在，返回true，否则返回false</param>
    function Exists(AData: Pointer; AHash: TQHashType): Boolean;
    /// <summary>删除指定哈希值的指定元素</summary>
    /// <param name="AData">要删除的元素值指针地址</param>
    /// <param name="AHash">AData对应的哈希值</param>
    procedure Delete(AData: Pointer; AHash: TQHashType); overload;
    procedure Delete(AHashList: PQHashList); overload;
    /// <summary>统计整个哈希桶的数据分布信息，以便用户改进哈希函数</summary>
    procedure Statics(var AResult: TQHashStatics);
    /// <summary>
    /// 更改一个数据的哈希值，如果这个数据不存在，则插入它
    /// </summary>
    /// <param name="AData"> 更改内容的数据</param>
    /// <param name="AOldHash"> 数据内容对应的原哈希值</param>
    /// <param name="ANewHash"> 数据内容变更完成后的新哈希值</param>
    procedure ChangeHash(AData: Pointer; AOldHash, ANewHash: TQHashType);
    /// <summary>清空整个列表</summary>
    procedure Clear;
    procedure ForEach(ACallback: TQHashNotify);
    function GetEnumerator: TQHashTableIterator;
    /// 元素个数
    property Count: Integer read FCount;
    /// 桶数量
    property BucketCount: Integer read GetBucketCount;
    /// 桶列表
    property Buckets[AIndex: Integer]: PQHashList read GetBuckets; default;
    /// 比较函数
    property OnCompare: TQRBCompare read FOnCompare write FOnCompare;
    /// 删除事件通知
    property OnDelete: TQHashNotify read FOnDelete write FOnDelete;
    /// <summary>在有一个桶被使用时触发</summary>
    /// <remarks>注意，如果AutoSize为True时，桶信息可能会在此事件后发生变更</remarks>
    property AfterBucketUsed: TQBucketNotify read FAfterBucketUsed
      write FAfterBucketUsed;
    /// <summary>在有一个桶变成空时触发</summary>
    property AfterBucketEmpty: TQBucketNotify read FAfterBucketEmpty
      write FAfterBucketEmpty;
    /// 是否自动调整桶大小
    property AutoSize: Boolean read FAutoSize write SetAutoSize;
  end;

  TQRBComparor = class
  private
  public
    function IntComp(P1, P2: Pointer): Integer;
    function SingleComp(P1, P2: Pointer): Integer;
    function FloatComp(P1, P2: Pointer): Integer;
    function Int64Comp(P1, P2: Pointer): Integer;
    function QStringWComp(P1, P2: Pointer): Integer;
    function QStringWCompI(P1, P2: Pointer): Integer;
    function Int2Pointer(const V: Integer): Pointer; inline;
    function Pointer2Int(const V: Pointer): Integer; inline;
  end;

var
  RBDefaultComparor: TQRBComparor;

implementation

uses qworker;

const
  RB_RED = 0;
  RB_BLACK = 1;

  { TQRBTree }
procedure TQRBTree.DoCopy(node1, node2: TQRBNode);
begin
  if Assigned(FOnCopy) then
    FOnCopy(Self, node1, node2);
end;

procedure TQRBTree.DoPropagate(node1, node2: TQRBNode);
begin
  if Assigned(FOnPropagate) then
    FOnPropagate(Self, node1, node2);
end;

procedure TQRBTree.ChangeChild(AOld, ANew, Parent: TQRBNode);
begin
  if Parent <> nil then
  begin
    if Parent.Left = AOld then
      Parent.Left := ANew
    else
      Parent.Right := ANew;
  end
  else
    FRoot := ANew;
end;

procedure TQRBTree.Clear;
var
  ANode: TQRBNode;
begin
  if Assigned(OnDelete) then
  begin
    ANode := First;
    while ANode <> nil do
    begin
      OnDelete(Self, ANode);
      ANode := ANode.Next;
    end;
  end;
  FreeAndNil(FRoot);
  FCount := 0;
end;

constructor TQRBTree.Create(AOnCompare: TQRBCompare);
begin
  inherited Create;
  FOnCompare := AOnCompare;
end;

destructor TQRBTree.Destroy;
begin
  Clear;
  inherited;
end;

procedure TQRBTree.DoRotate(AOld, ANew: TQRBNode);
begin
  if Assigned(FOnRotate) then
    FOnRotate(Self, AOld, ANew);
end;

function TQRBTree.Delete(AChild: TQRBNode): Pointer;
var
  rebalance: TQRBNode;
begin
  // Todo:Remove debug
  Result := AChild.Data;
  rebalance := EraseAugmented(AChild);
  if rebalance <> nil then
    EraseColor(rebalance);
  AChild.FLeft := nil;
  AChild.FRight := nil;
  Dec(FCount);
  if Assigned(FOnDelete) then
    FOnDelete(Self, AChild);
  FreeObject(AChild);
{$IFDEF PRINT_TREE}PrintTree('After delete ' + IntToHex(IntPtr(AChild), 8));
  {$ENDIF}
end;

function TQRBTree.EraseAugmented(node: TQRBNode): TQRBNode;
var
  child, tmp, AParent, rebalance: TQRBNode;
  pc, pc2: IntPtr;
  successor, child2: TQRBNode;
begin
  child := node.Right;
  tmp := node.Left;
  if tmp = nil then
  begin
    pc := node.FParent_Color;
    AParent := node.Parent;
    ChangeChild(node, child, AParent);
    if Assigned(child) then
    begin
      child.FParent_Color := pc;
      rebalance := nil;
    end
    else if (pc and RB_BLACK) <> 0 then
      rebalance := AParent
    else
      rebalance := nil;
    tmp := AParent;
  end
  else if not Assigned(child) then
  begin
    tmp.FParent_Color := node.FParent_Color;
    AParent := node.Parent;
    ChangeChild(node, tmp, AParent);
    rebalance := nil;
    tmp := AParent;
  end
  else
  begin
    successor := child;
    tmp := child.Left;
    if not Assigned(tmp) then
    begin
      AParent := successor;
      child2 := successor.Right;
      DoCopy(node, successor);
    end
    else
    begin
      repeat
        AParent := successor;
        successor := tmp;
        tmp := tmp.Left;
      until tmp = nil;
      AParent.Left := successor.Right;
      child2 := successor.Right;
      successor.Right := child;
      child.Parent := successor;
      DoCopy(node, successor);
      DoPropagate(AParent, successor);
    end;
    successor.Left := node.Left;
    tmp := node.Left;
    tmp.Parent := successor;
    pc := node.FParent_Color;
    tmp := node.Parent;
    ChangeChild(node, successor, tmp);
    if Assigned(child2) then
    begin
      successor.FParent_Color := pc;
      child2.SetParentColor(AParent, RB_BLACK);
      rebalance := nil;
    end
    else
    begin
      pc2 := successor.FParent_Color;
      successor.FParent_Color := pc;
      if (pc2 and RB_BLACK) <> 0 then
        rebalance := AParent
      else
        rebalance := nil;
    end;
    tmp := successor;
  end;
  DoPropagate(tmp, nil);
  Result := rebalance;
end;

procedure TQRBTree.EraseColor(AParent: TQRBNode);
var
  node, sibling, tmp1, tmp2: TQRBNode;
begin
  node := nil;
  while (true) do
  begin
    sibling := AParent.Right;
    if node <> sibling then
    begin
{$REGION 'node<>sibling'}
      if sibling.IsRed then
{$REGION 'slbling.IsRed'}
      begin
        AParent.Right := sibling.Left;
        tmp1 := sibling.Left;
        sibling.Left := AParent;
        tmp1.SetParentColor(AParent, RB_BLACK);
        RotateSetParents(AParent, sibling, RB_RED);
        DoRotate(AParent, sibling);
        sibling := tmp1;
      end;
{$ENDREGION 'slbling.IsRed'}
      tmp1 := sibling.Right;
      if (not Assigned(tmp1)) or tmp1.IsBlack then
      begin
{$REGION 'tmp1.IsBlack'}
        tmp2 := sibling.Left;
        if (not Assigned(tmp2)) or tmp2.IsBlack then
        begin
{$REGION 'tmp2.IsBlack'}
          sibling.SetParentColor(AParent, RB_RED);
          if AParent.IsRed then
            AParent.SetBlack
          else
          begin
            node := AParent;
            AParent := node.Parent;
            if Assigned(AParent) then
              Continue;
          end;
          Break;
{$ENDREGION 'tmp2.IsBlack'}
        end;
        sibling.Left := tmp2.Right;
        tmp1 := tmp2.Right;
        tmp2.Right := sibling;
        AParent.Right := tmp2;
        if Assigned(tmp1) then
          tmp1.SetParentColor(sibling, RB_BLACK);
        DoRotate(sibling, tmp2);
        tmp1 := sibling;
        sibling := tmp2;
{$ENDREGION 'tmp1.IsBlack'}
      end;
      AParent.Right := sibling.Left;
      tmp2 := sibling.Left;
      sibling.Left := AParent;
      tmp1.SetParentColor(sibling, RB_BLACK);
      if Assigned(tmp2) then
        tmp2.Parent := AParent;
      RotateSetParents(AParent, sibling, RB_BLACK);
      DoRotate(AParent, sibling);
      Break;
{$ENDREGION 'node<>sibling'}
    end
    else
    begin
{$REGION 'RootElse'}
      sibling := AParent.Left;
      if (sibling.IsRed) then
      begin
{$REGION 'Case 1 - right rotate at AParent'}
        AParent.Left := sibling.Right;
        tmp1 := sibling.Right;
        sibling.Right := AParent;
        tmp1.SetParentColor(AParent, RB_BLACK);
        RotateSetParents(AParent, sibling, RB_RED);
        DoRotate(AParent, sibling);
        sibling := tmp1;
{$ENDREGION 'Case 1 - right rotate at AParent'}
      end;
      tmp1 := sibling.Left;
      if (tmp1 = nil) or tmp1.IsBlack then
      begin
{$REGION 'tmp1.IsBlack'}
        tmp2 := sibling.Right;
        if (tmp2 = nil) or tmp2.IsBlack then
        begin
{$REGION 'tmp2.IsBlack'}
          sibling.SetParentColor(AParent, RB_RED);
          if AParent.IsRed then
            AParent.SetBlack
          else
          begin
            node := AParent;
            AParent := node.Parent;
            if Assigned(AParent) then
              Continue;
          end;
          Break;
{$ENDREGION 'tmp2.IsBlack'}
        end;
        sibling.Right := tmp2.Left;
        tmp1 := tmp2.Left;
        tmp2.Left := sibling;
        AParent.Left := tmp2;
        if Assigned(tmp1) then
          tmp1.SetParentColor(sibling, RB_BLACK);
        DoRotate(sibling, tmp2);
        tmp1 := sibling;
        sibling := tmp2;
{$ENDREGION ''tmp1.IsBlack'}
      end;
      AParent.Left := sibling.Right;
      tmp2 := sibling.Right;
      sibling.Right := AParent;
      tmp1.SetParentColor(sibling, RB_BLACK);
      if Assigned(tmp2) then
        tmp2.Parent := AParent;
      RotateSetParents(AParent, sibling, RB_BLACK);
      DoRotate(AParent, sibling);
      Break;
{$ENDREGION 'RootElse'}
    end;
  end;
end;

function TQRBTree.Find(AData: Pointer): TQRBNode;
var
  rc: Integer;
begin
  Result := FRoot;
  while Assigned(Result) do
  begin
    rc := OnCompare(AData, Result.Data);
    if rc < 0 then
      Result := Result.Left
    else if rc > 0 then
      Result := Result.Right
    else
      Break;
  end
end;

function TQRBTree.First: TQRBNode;
begin
  Result := FRoot;
  if Result <> nil then
  begin
    while Assigned(Result.Left) do
      Result := Result.Left;
  end;
end;

function TQRBTree.FirstPostOrder: TQRBNode;
begin
  if Assigned(FRoot) then
    Result := FRoot.LeftDeepest
  else
    Result := nil;
end;

function TQRBTree.GetIsEmpty: Boolean;
begin
  Result := (FRoot = nil);
end;

procedure TQRBTree.InsertColor(AChild: TQRBNode);
begin
  InsertNode(AChild);
end;

// static __always_inline void
// __rb_insert(struct rb_node *node, struct rb_root *root,
/// void (*augment_rotate)(struct rb_node *old, struct rb_node *new))
function TQRBTree.Insert(AData: Pointer): Boolean;
var
  new: PQRBNode;
  Parent, AChild: TQRBNode;
  rc: Integer;
begin
  new := @FRoot;
  Parent := nil;
  while new^ <> nil do
  begin
    rc := OnCompare(AData, new.Data);
    Parent := new^;
    if rc < 0 then
      new := @new^.FLeft
    else if rc > 0 then
      new := @new^.FRight
    else // 已存在
    begin
      Result := False;
      Exit;
    end;
  end;
  AChild := TQRBNode.Create;
  AChild.Data := AData;
  LinkNode(AChild, Parent, new^);
  InsertColor(AChild);
  Inc(FCount);
  Result := true;
end;

procedure TQRBTree.InsertNode(node: TQRBNode);
var
  AParent, GParent, tmp: TQRBNode;
begin
  AParent := node.RedParent;
  while true do
  begin
    if AParent = nil then
    begin
      node.SetParentColor(nil, RB_BLACK);
      Break;
    end
    else if AParent.IsBlack then
      Break;
    GParent := AParent.RedParent;
    tmp := GParent.Right;
    if AParent <> tmp then
    begin
      if Assigned(tmp) and tmp.IsRed then
      begin
        tmp.SetParentColor(GParent, RB_BLACK);
        AParent.SetParentColor(GParent, RB_BLACK);
        node := GParent;
        AParent := node.Parent;
        node.SetParentColor(AParent, RB_RED);
        Continue;
      end;
      tmp := AParent.Right;
      if node = tmp then
      begin
        AParent.Right := node.Left;
        tmp := node.Left;
        node.Left := AParent;
        if Assigned(tmp) then
          tmp.SetParentColor(AParent, RB_BLACK);
        AParent.SetParentColor(node, RB_RED);
        DoRotate(AParent, node); // augment_rotate(parent,node)
        AParent := node;
        tmp := node.Right;
      end;
      GParent.Left := tmp;
      AParent.Right := GParent;
      if tmp <> nil then
        tmp.SetParentColor(GParent, RB_BLACK);
      RotateSetParents(GParent, AParent, RB_RED);
      DoRotate(GParent, AParent);
      Break;
    end
    else
    begin
      tmp := GParent.Left;
      if Assigned(tmp) and tmp.IsRed then
      begin
        tmp.SetParentColor(GParent, RB_BLACK);
        AParent.SetParentColor(GParent, RB_BLACK);
        node := GParent;
        AParent := node.Parent;
        node.SetParentColor(AParent, RB_RED);
        Continue;
      end;
      tmp := AParent.Left;
      if node = tmp then
      begin
        AParent.Left := node.Right;
        tmp := node.Right;
        node.Right := AParent;
        if tmp <> nil then
          tmp.SetParentColor(AParent, RB_BLACK);
        AParent.SetParentColor(node, RB_RED);
        DoRotate(AParent, node);
        AParent := node;
        tmp := node.Left;
      end;
      GParent.Right := tmp;
      AParent.Left := GParent;
      if tmp <> nil then
        tmp.SetParentColor(GParent, RB_BLACK);
      RotateSetParents(GParent, AParent, RB_RED);
      DoRotate(GParent, AParent);
      Break;
    end;
  end;
  {$IFDEF PRINT_TREE}
  PrintTree('After insert ' + IntToHex(IntPtr(node), 8));
  {$ENDIF}
end;

function TQRBTree.Last: TQRBNode;
begin
  Result := FRoot;
  if Result <> nil then
  begin
    while Assigned(Result.Right) do
      Result := Result.Right;
  end;
end;

procedure TQRBTree.LinkNode(node, Parent: TQRBNode; var rb_link: TQRBNode);
begin
  node.FParent_Color := IntPtr(Parent);
  node.FLeft := nil;
  node.FRight := nil;
  rb_link := node;
end;
{$IFDEF PRINT_TREE}

procedure TQRBTree.PrintTree(AHint: String);
var
  AFirst, ANode: TQRBNode;
  S: String;
  C, I: Integer;
  AStacks: array [0 .. 49] of Pointer;
  AErrorFound: Boolean;
begin
  ANode := First;
  AFirst := ANode;
  S := AHint + '==>' + SLineBreak;
  C := 0;
  AErrorFound := False;
  S := S + Format('Node %X Left=%X Right=%X Parent=%X Color:%X',
    [IntPtr(FRoot), IntPtr(FRoot.Left), IntPtr(FRoot.Right),
    IntPtr(FRoot.Parent), FRoot.FParent_Color]) + SLineBreak;
  while Assigned(ANode) do
  begin
    AStacks[C] := ANode;
    S := S + Format('Node %X Left=%X Right=%X Parent=%X Data:%X',
      [IntPtr(ANode), IntPtr(ANode.Left), IntPtr(ANode.Right),
      IntPtr(ANode.Parent), ANode.FParent_Color]) + SLineBreak;
    ANode := ANode.Next;
    for I := 0 to C do
    begin
      if AStacks[I] = ANode then
      begin
        AErrorFound := true;
        Break;
      end;
    end;
    Inc(C);
    if (ANode = AFirst) or (C > 50) then
    begin
      AErrorFound := True;
      Break;
    end;
  end;
  if AErrorFound then
    S := S + '!!!!!Tree node errors!!!!' + SLineBreak;
  PostLog(llDebug, S);
  if AErrorFound then
  begin
    while Logs.Flushed < Logs.Count do
      Sleep(100);
    DebugBreak;
  end;
end;
{$ENDIF}

procedure TQRBTree.Replace(victim, ANew: TQRBNode);
var
  Parent: TQRBNode;
begin
  Parent := victim.Parent;
  ChangeChild(victim, ANew, Parent);
  if Assigned(victim.Left) then
    victim.Left.SetParent(ANew)
  else
    victim.Right.SetParent(ANew);
  ANew.Assign(victim);
end;

// __rb_rotate_set_parents(struct rb_node *old, struct rb_node *new,struct rb_root *root, int color)
{
  struct rb_node *parent = rb_parent(old);
  new->__rb_parent_color = old->__rb_parent_color;
  rb_set_parent_color(old, new, color);
  __rb_change_child(old, new, parent, root);
}
procedure TQRBTree.RotateSetParents(AOld, ANew: TQRBNode; color: Integer);
var
  AParent: TQRBNode;
begin
  AParent := AOld.Parent;
  ANew.FParent_Color := AOld.FParent_Color;
  AOld.SetParentColor(ANew, color);
  ChangeChild(AOld, ANew, AParent);
end;

{ TQRBNode }

procedure TQRBNode.Assign(src: TQRBNode);
begin
  FParent_Color := src.FParent_Color;
  FLeft := src.FLeft;
  FRight := src.FRight;
  FData := src.FData;
end;

procedure TQRBNode.Clear;
begin
  FParent_Color := IntPtr(Self);
end;

constructor TQRBNode.Create;
begin
  inherited;
end;

destructor TQRBNode.Destroy;
begin
  if Assigned(FLeft) then
    FreeObject(FLeft);
  if Assigned(FRight) then
    FreeObject(FRight);
  inherited;
end;

function TQRBNode.GetIsBlack: Boolean;
begin
  Result := (IntPtr(FParent_Color) and $1) <> 0;
end;

function TQRBNode.GetIsEmpty: Boolean;
begin
  Result := (FParent_Color = IntPtr(Self));
end;

function TQRBNode.GetIsRed: Boolean;
begin
  Result := ((IntPtr(FParent_Color) and $1) = 0);
end;

function TQRBNode.GetLeftDeepest: TQRBNode;
begin
  Result := Self;
  while true do
  begin
    if Assigned(Result.Left) then
      Result := Result.Left
    else if Assigned(Result.Right) then
      Result := Result.Right
    else
      Break;
  end;
end;

function TQRBNode.GetNext: TQRBNode;
var
  node, AParent: TQRBNode;
begin
  if IsEmpty then
    Result := nil
  else
  begin
    if Assigned(FRight) then
    begin
      Result := FRight;
      while Assigned(Result.Left) do
        Result := Result.Left;
      Exit;
    end;
    node := Self;
    repeat
      AParent := node.Parent;
      if Assigned(AParent) and (node = AParent.Right) then
        node := AParent
      else
        Break;
    until AParent = nil;
    Result := AParent;
  end;
end;

function TQRBNode.GetParent: TQRBNode;
begin
  Result := TQRBNode(IntPtr(FParent_Color) and (not $3));
end;

function TQRBNode.GetPrior: TQRBNode;
var
  node, AParent: TQRBNode;
begin
  if IsEmpty then
    Result := nil
  else
  begin
    if Assigned(FLeft) then
    begin
      Result := FLeft;
      while Assigned(Result.Right) do
        Result := Result.Right;
      Exit;
    end;
    node := Self;
    repeat
      AParent := node.Parent;
      if Assigned(Parent) and (node = AParent.Left) then
        node := AParent
      else
        Break;
    until AParent = nil;
    Result := AParent;
  end;
end;

function TQRBNode.NextPostOrder: TQRBNode;
begin
  Result := Parent;
  if Assigned(Result) and (Self = Result.Left) and Assigned(Result.Right) then
    Result := Result.Right.LeftDeepest;
end;
// struct rb_node *rb_red_parent(struct rb_node *red)

function TQRBNode.RedParent: TQRBNode;
begin
  Result := TQRBNode(FParent_Color);
end;

// rbtree.c rb_set_black(struct rb_node *rb)
procedure TQRBNode.SetBlack;
begin
  FParent_Color := FParent_Color or RB_BLACK;
end;

procedure TQRBNode.SetParent(const Value: TQRBNode);
begin
  FParent_Color := IntPtr(Value) or (IntPtr(FParent_Color) and $1);
end;

procedure TQRBNode.SetParentColor(AParent: TQRBNode; AColor: Integer);
begin
  FParent_Color := IntPtr(AParent) or AColor;
end;

{ TQHashTable }

procedure TQHashTable.Add(AData: Pointer; AHash: TQHashType);
var
  AIndex: Integer;
  ABucket: PQHashList;
begin
{$IFDEF DEBUG_EXISTS}
  DebugOut('Try add item %x(Hash:%d)', [IntPtr(AData), AHash]);
  if Exists(AData, AHash) then
  begin
    DebugOut('Duplicates Item %x(Hash:%d) found.Exit', [IntPtr(AData), AHash]);
    Exit;
  end;
{$ENDIF}
  BuncketsNeeded;
  new(ABucket);
  ABucket.Hash := AHash;
  ABucket.Data := AData;
  AIndex := AHash mod Cardinal(Length(FBuckets));
  ABucket.Next := FBuckets[AIndex];
  FBuckets[AIndex] := ABucket;
  Inc(FCount);
  if (not Assigned(ABucket.Next)) and Assigned(FAfterBucketUsed) then
    FAfterBucketUsed(Self, AIndex);
  if FAutoSize and ((FCount div Length(FBuckets)) > 3) then
    Resize(0);
end;

procedure TQHashTable.BuncketsNeeded;
begin
  if Length(FBuckets) = 0 then
    Resize(17);
end;

procedure TQHashTable.ChangeHash(AData: Pointer;
  AOldHash, ANewHash: TQHashType);
var
  AList, APrior: PQHashList;
  ACmpResult: Integer;
  AIndex: Integer;
  AChanged: Boolean;
begin
  AChanged := False;
  AIndex := AOldHash mod Cardinal(Length(FBuckets));
  AList := FBuckets[AIndex];
  APrior := nil;
  while AList <> nil do
  begin
    if (AList.Hash = AOldHash) then
    begin
      if (AList.Data = AData) or (Compare(AData, AList.Data, ACmpResult) and
        (ACmpResult = 0)) then
      begin
        if Assigned(APrior) then
          APrior.Next := AList.Next
        else
          FBuckets[AIndex] := AList.Next;
        AList.Hash := ANewHash;
        AIndex := ANewHash mod Cardinal(Length(FBuckets));
        AList.Next := FBuckets[AIndex];
        FBuckets[AIndex] := AList;
        AChanged := true;
        Break;
      end;
    end;
    APrior := AList;
    AList := AList.Next;
  end;
  if not AChanged then
    Add(AData, ANewHash);
end;

procedure TQHashTable.Clear;
var
  I, H: Integer;
  ABucket: PQHashList;
begin
  H := High(FBuckets);
  for I := 0 to H do
  begin
    ABucket := FBuckets[I];
    if ABucket <> nil then
    begin
      while ABucket <> nil do
      begin
        FBuckets[I] := ABucket.Next;
        DoDelete(ABucket.Hash, ABucket.Data);
        Dispose(ABucket);
        ABucket := FBuckets[I];
      end;
      if Assigned(FAfterBucketEmpty) then
        FAfterBucketEmpty(Self, I);
    end;
  end;
  FCount := 0;
end;

function TQHashTable.Compare(Data1, Data2: Pointer;
  var AResult: Integer): Boolean;
begin
  if Assigned(FOnCompare) then
  begin
    AResult := FOnCompare(Data1, Data2);
    Result := true;
  end
  else
    Result := False;
end;

constructor TQHashTable.Create;
begin
  inherited;
  Resize(0);
end;

constructor TQHashTable.Create(ASize: Integer);
begin
  if ASize = 0 then
    ASize := 17;
  Resize(ASize);
end;

procedure TQHashTable.Delete(AData: Pointer; AHash: TQHashType);
var
  AIndex, ACompare: Integer;
  AHashList, APrior: PQHashList;
begin
  AIndex := AHash mod Cardinal(Length(FBuckets));
  AHashList := FBuckets[AIndex];
  APrior := nil;
  while Assigned(AHashList) do
  begin
    if (AHashList.Data = AData) or
      ((Compare(AHashList.Data, AData, ACompare) and (ACompare = 0))) then
    // 同一数据，哈希值我们只能认为是相同，如果不同，找上帝去吧
    begin
      InternalDelete(AIndex, APrior, AHashList);
      Break;
    end
    else
    begin
      APrior := AHashList;
      AHashList := APrior.Next;
    end;
  end;
end;

procedure TQHashTable.Delete(AHashList: PQHashList);
var
  AIndex: Integer;
  APrior: PQHashList;
begin
  AIndex := AHashList.Hash mod Cardinal(Length(FBuckets));
  APrior := FBuckets[AIndex];
  if APrior = AHashList then
    InternalDelete(AIndex, nil, AHashList)
  else
  begin
    while Assigned(APrior) and (APrior.Next <> AHashList) do
      APrior := APrior.Next;
    if Assigned(APrior) then
      InternalDelete(AIndex, APrior, AHashList);
  end;
end;

destructor TQHashTable.Destroy;
begin
  Clear;
  inherited;
end;

procedure TQHashTable.DoDelete(AHash: TQHashType; AData: Pointer);
begin
  if Assigned(FOnDelete) then
    FOnDelete(Self, AHash, AData);
end;

function TQHashTable.Exists(AData: Pointer; AHash: TQHashType): Boolean;
var
  AList: PQHashList;
  AResult: Integer;
begin
  AList := FindFirst(AHash);
  Result := False;
  while AList <> nil do
  begin
    if (AList.Data = AData) or (Compare(AList.Data, AData, AResult) and
      (AResult = 0)) then
    begin
      Result := true;
      Break;
    end;
    AList := FindNext(AList);
  end;
end;

function TQHashTable.Find(AHash: TQHashType): PQHashList;
var
  AIndex: Integer;
  AList, AItem: PQHashList;
begin
  AIndex := AHash mod Cardinal(Length(FBuckets));
  Result := nil;
  AList := FBuckets[AIndex];
  while AList <> nil do
  begin
    if AList.Hash = AHash then
    begin
      new(AItem);
      AItem.Data := AList.Data;
      AItem.Next := Result;
      AItem.Hash := AHash;
      Result := AItem;
    end;
    AList := AList.Next;
  end;
end;

function TQHashTable.Find(AData: Pointer; AHash: TQHashType): Pointer;
var
  ACmpResult: Integer;
  AList: PQHashList;
begin
  Result := nil;
  AList := FindFirst(AHash);
  while AList <> nil do
  begin
    if (AList.Data = AData) or (Compare(AData, AList.Data, ACmpResult) and
      (ACmpResult = 0)) then
    begin
      Result := AList.Data;
      Break;
    end;
    AList := AList.Next;
  end;
end;

function TQHashTable.FindFirst(AHash: TQHashType): PQHashList;
var
  AIndex: Integer;
  AList: PQHashList;
begin
  Result := nil;
  if Length(FBuckets) > 0 then
  begin
    AIndex := AHash mod Cardinal(Length(FBuckets));
    AList := FBuckets[AIndex];
    while AList <> nil do
    begin
      if AList.Hash = AHash then
      begin
        Result := AList;
        Break;
      end;
      AList := AList.Next;
    end;
  end;
end;

function TQHashTable.FindFirstData(AHash: TQHashType): Pointer;
var
  AList: PQHashList;
begin
  AList := FindFirst(AHash);
  if AList <> nil then
    Result := AList.Data
  else
    Result := nil;
end;

function TQHashTable.FindNext(AList: PQHashList): PQHashList;
begin
  Result := nil;
  if Assigned(AList) then
  begin
    Result := AList.Next;
    while Result <> nil do
    begin
      if Result.Hash = AList.Hash then
        Break
      else
        Result := Result.Next;
    end;
  end;
end;

procedure TQHashTable.ForEach(ACallback: TQHashNotify);
var
  I, H: Integer;
  ABucket: PQHashList;
begin
  H := High(FBuckets);
  for I := 0 to H do
  begin
    ABucket := FBuckets[I];
    while ABucket <> nil do
    begin
      ACallback(Self, ABucket.Hash, ABucket.Data);
      ABucket := ABucket.Next;
    end;
  end;
end;

procedure TQHashTable.FreeHashList(AList: PQHashList);
var
  ANext: PQHashList;
begin
  while AList <> nil do
  begin
    ANext := AList.Next;
    Dispose(AList);
    AList := ANext;
  end;
end;

function TQHashTable.GetBucketCount: Integer;
begin
  Result := Length(FBuckets);
end;

function TQHashTable.GetBuckets(AIndex: Integer): PQHashList;
begin
  Result := FBuckets[AIndex];
end;

function TQHashTable.GetEnumerator: TQHashTableIterator;
begin
  Result := TQHashTableIterator.Create(Self);
end;

procedure TQHashTable.InternalDelete(AIndex: Integer;
  APrior, AHashList: PQHashList);
begin
  DoDelete(AHashList.Hash, AHashList.Data);
  if Assigned(APrior) then
    APrior.Next := AHashList.Next
  else
    FBuckets[AIndex] := AHashList.Next;
  if FBuckets[AIndex] = nil then
  begin
    if Assigned(FAfterBucketEmpty) then
      FAfterBucketEmpty(Self, AIndex);
  end;
  Dispose(AHashList);
  Dec(FCount);
  if FAutoSize then
  begin
    if FCount * 3 < Length(FBuckets) then
      Resize(0);
  end;
end;

procedure TQHashTable.Resize(ASize: Cardinal);
const
  // 28个默认的桶尺寸，在ASize=0时应用
  BucketSizes: array [0 .. 27] of Integer = (17, 37, 79, 163, 331, 673, 1361,
    2729, 5471, 10949, 21911, 43853, 87719, 175447, 350899, 701819, 1403641,
    2807303, 5614657, 11229331, 22458671, 44917381, 89834777, 179669557,
    359339171, 718678369, 1437356741, 2147483647);
var
  I, AIndex: Integer;
  AHash: Cardinal;
  ALastBuckets: TQHashArray;
  AList, ANext: PQHashList;
begin
  if ASize = 0 then
  begin
    if FCount > 0 then
    begin
      for I := 0 to 27 do
      begin
        if BucketSizes[I] > FCount then
        begin
          ASize := BucketSizes[I];
          Break;
        end;
      end;
      if ASize = 0 then // 最大的桶大小
        ASize := BucketSizes[27];
      if ASize = Cardinal(Length(FBuckets)) then
        Exit;
    end;
  end;
  if ASize <> Cardinal(Length(FBuckets)) then
  begin
    // 桶尺寸变更后，重新分配元素所在的哈希桶，如果是自动调用的话，理想的结果就是一个桶有一个元素
    ALastBuckets := FBuckets;
    SetLength(FBuckets, ASize);
    for I := 0 to ASize - 1 do
      FBuckets[I] := nil;
    for I := 0 to High(ALastBuckets) do
    begin
      AList := ALastBuckets[I];
      while AList <> nil do
      begin
        AHash := AList.Hash;
        AIndex := AHash mod ASize;
        ANext := AList.Next;
        AList.Next := FBuckets[AIndex];
        FBuckets[AIndex] := AList;
        AList := ANext;
      end;
    end;
  end;
end;

procedure TQHashTable.SetAutoSize(const Value: Boolean);
begin
  if FAutoSize <> Value then
  begin
    FAutoSize := Value;
    if AutoSize then
    begin
      if (Length(FBuckets) > 0) and ((FCount div Length(FBuckets)) > 3) then
        Resize(0);
    end;
  end;
end;

procedure TQHashTable.Statics(var AResult: TQHashStatics);
var
  I, L, D: Integer;
  AList: PQHashList;
  ADeptList: array of Integer;
begin
  L := Length(FBuckets);
  AResult.Count := 0;
  AResult.MaxDepth := 0;
  AResult.TotalDepth := 0;
  SetLength(ADeptList, L);
  for I := 0 to L - 1 do
  begin
    AList := FBuckets[I];
    if AList <> nil then
    begin
      D := 0;
      while AList <> nil do
      begin
        Inc(D);
        AList := AList.Next;
      end;
      if D > AResult.MaxDepth then
      begin
        AResult.MaxDepth := D;
        AResult.MaxItems := FBuckets[I];
      end;
      Inc(AResult.Count);
      Inc(AResult.TotalDepth, D);
      ADeptList[I] := D;
    end;
  end;
  SetLength(AResult.DepthList, AResult.MaxDepth);
  if AResult.Count > 0 then
    AResult.AvgDepth := AResult.TotalDepth / AResult.Count;
  for I := 0 to L - 1 do
  begin
    D := ADeptList[I];
    if D <> 0 then
      Inc(AResult.DepthList[D - 1]);
  end;
end;

{ TQHashTableIterator }

constructor TQHashTableIterator.Create(AList: TQHashTable);
begin
  inherited Create;
  FCurrent := nil;
  FList := AList;
  FBucket := -1;
end;

function TQHashTableIterator.GetCurrent: PQHashList;
begin
  Result := FCurrent;
end;

function TQHashTableIterator.MoveNext: Boolean;
begin
  if FCurrent <> nil then
  begin
    FCurrent := FCurrent.Next;
    if FCurrent = nil then
    begin
      Inc(FBucket);
      while FBucket < FList.BucketCount do
      begin
        FCurrent := FList.Buckets[FBucket];
        if Assigned(FCurrent) then
          Break;
        Inc(FBucket);
      end;
    end;
  end
  else
  begin
    FBucket := 0;
    while FBucket < FList.BucketCount do
    begin
      FCurrent := FList.Buckets[FBucket];
      if Assigned(FCurrent) then
        Break;
    end;
  end;
  Result := FCurrent <> nil;
end;

{ TQRBComparor }

function TQRBComparor.IntComp(P1, P2: Pointer): Integer;
var
  R: IntPtr;
begin
  R := IntPtr(P1) - IntPtr(P2);
  if R < 0 then
    Result := -1
  else if R > 0 then
    Result := 1
  else
    Result := 0;
end;

function TQRBComparor.Pointer2Int(const V: Pointer): Integer;
begin
  Result := IntPtr(V);
end;

function TQRBComparor.FloatComp(P1, P2: Pointer): Integer;
begin
  if PDouble(P1)^ < PDouble(P2)^ then
    Result := -1
  else if PDouble(P1)^ > PDouble(P2)^ then
    Result := 1
  else
    Result := 0;
end;

function TQRBComparor.Int2Pointer(const V: Integer): Pointer;
begin
  Result := Pointer(V);
end;

function TQRBComparor.Int64Comp(P1, P2: Pointer): Integer;
begin
  Result := PInt64(P1)^ - PInt64(P2)^;
end;

function TQRBComparor.QStringWComp(P1, P2: Pointer): Integer;
begin
  Result := StrCmpW(PQCharW(PQStringW(P1)^), PQCharW(PQStringW(P2)^), False);
end;

function TQRBComparor.QStringWCompI(P1, P2: Pointer): Integer;
begin
  Result := StrCmpW(PQCharW(PQStringW(P1)^), PQCharW(PQStringW(P2)^), true);
end;

function TQRBComparor.SingleComp(P1, P2: Pointer): Integer;
begin
  if PSingle(P1)^ < PSingle(P2)^ then
    Result := -1
  else if PSingle(P1)^ > PSingle(P2)^ then
    Result := 1
  else
    Result := 0;
end;


initialization

RBDefaultComparor := TQRBComparor.Create;

finalization

FreeAndNil(RBDefaultComparor);

end.
