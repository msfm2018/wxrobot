unit qworker;
{$I 'qdac.inc'}

interface

// 该宏决定是否启用QMapSymbols单元来获取函数名称，否则可能取不到真正的名称，而只能是地址
{$IFDEF MSWINDOWS}
{ .$DEFINE USE_MAP_SYMBOLS }
{ .$DEFINE DEBUGOUT }
{$ENDIF}
// 在线程数太多时TQSimpleLock的自旋带来过多的开销，反而不如临界，所以暂时放弃使用

{ .$DEFINE QWORKER_SIMPLE_LOCK }
{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的JSON解析器来自QDAC项目中的QJSON，版权归作者所有。
  (2)、技术支持
  有技术问题，您可以加入QDAC官方QQ群250530692共同探讨。
  (3)、赞助
  您可以自由使用本源码而不需要支付任何费用。如果您觉得本源码对您有帮助，您可以赞
  助本项目（非强制），以使作者不为生活所迫，有更多的精力为您呈现更好的作品：
  赞助方式：
  支付宝： guansonghuan@sina.com 姓名：管耸寰
  建设银行：
  户名：管耸寰
  账号：4367 4209 4324 0179 731
  开户行：建设银行长春团风储蓄所
}
{$REGION '修订日志'}
{ 修订日志
  2018.10.20
  ==========
  * 统一匿名函数规则和其它组件一致，均是标记 TMehtod.Data 为 -1
  * 修正了 WaitRunningDone 为 false 时没有清理正在运行的作业的问题（丰盛辉煌报告）
  + Clear 函数加入了几个重载
  2017.5.8
  ==========
  * 修订了 DLL 中主线程作业可能无法执行的问题
  * 修订了调用 Clear 清理作业后投递新计划任务作业无法执行的问题（麦子仲肥报告）
  2017.1.10
  ==========
  * 修订了延迟重复作业无法通过作业中设置 AJob.IsTerminated 停止的问题（九木报告）

  2016.11.15
  ==========
  * 修正了ClearSingleJob/ClearSingleJobs 清理重复作业时没有正确标记作业状态的问题(乱世虾仁报告)
  * 修正了WaitRunningDone没有等待作业清理完成就退出的问题（MLSkin报告）

  2016.10.11
  ==========
  * 修正了由于算术溢出造成 WaitSignal 直接退出的问题（阿木报告）

  2016.7.14
  ==========
  * 修改了信号作业的容器，以提高按ID访问时的效率
  * 修正了信号作业清理不干净的问题（MLSkin报告）
  2016.7.6
  ==========
  * 修正了 SignalIdByName 函数的算法逻辑错误，造成可能无法触发相应的信号作业的问题
  + 优化信号通过名称访问的逻辑，提高按信号名称访问时的速度

  2016.6.24
  ==========
  * 修改了 Delay 的定间隔重复作业的处理逻辑，解决掉特定情况下无法正确清理的问题（乱世虾仁报告）
  * 修正了信号作业的在特定场景下出现AV错误的问题

  2016.6.23
  ==========
  * 修正了 Delay 的重复作业清理时有可能未清理成功的问题（乱世虾仁报告）
  + 信号作业加入了依赖于触发顺序的信号作业支持，通过 SignalQueue 属性的 Post 方法提供支持（MLSkin 建议）

  2016.5.3
  ==========
  * 计划任务作业的计划中增加末次执行时间的记录
  * 修正了 SetMaxWorkers 中检查MinWorkers值错误的问题（D7 报告）
  2016.5.2
  ==========
  * 修正了 RunInMainThread 全局函数参数未正确传递的问题（青铜时代报告）
  2016.4.21
  ==========
  * TQForJobs 的构造函数的 AFreeType 增加默认值
  + TQForJobs 增加 Run 函数，以便单独运行
  * 修改了 Delay 函数的下次执行时间计算时机
  * 修正了 Delay 函数没有更新作业统计信息的问题
  * 修正了 Plan 触发的作业用户指定附加数据释放方式没有正确处理的问题
  2016.4.11
  =========
  * 修正了 EnumJobStates 和 PeekJobState 返回的运行中作业状态不正确的问题（青春报告）
  * 修改了 At 传递日期时间类型为参数的行为，改为不忽略日期时间类型中的日期部分（青春报告）

  2016.3.16
  ==========
  * 修正了特定场景下，空闲工作者被全部解雇的问题（LakeView报告）

  2016.2.23
  ==========
  * 修正了 WaitJob 在特定场景下，造成作业不会被工作者及时调用的问题（成浩报告）
  2016.1.23
  ==========
  * 将 MsgWaitForEvent 函数公开
  2016.1.8
  ==========
  * 修正了 WaitJob 循环普通作业时，未正确调用AJob.Next下一个作业的问题（小朱报告）
  2015.11.20
  ==========
  + 增加 WaitJob 来等待一个普通作业超时或完成（阿木建议）
  * 修改了 TQJob 的结构，避免 Source 影响重复作业的 Interval 和 FirstDelay 参数（大丁报告）
  2015.11.6
  =========
  * 修正了由于匿名 ClearJobState 的问题，造成包含匿名作业处理函数时，退出时内存泄露的问题（阿木报告）
  2015.8.27
  =========
  * 修正了 TQJobGroup.Add 对匿名函数支持版本的问题

  2015.8.11
  =========
  * 修正了计划任务作业超时失效时，清理的算法错误
  * 计划任务作业的支持更复杂的表达式，精度提高到秒（阿木提供相关资料）
  2015.7.27
  =========
  * 修正了 SetMaxWorkers 时长时间作业数量没有跟着变更的问题

  2015.7.3
  =========
  * 修正了周次计算函数错误，造成周次检查条件无效的问题（青春报告）
  2015.6.16
  ==========
  * 修正了TQJobGroup.Cancel时，已投寄的作业没有正确取消的问题（浪迹报告）
  * 修改TQJobGroup.Cancel取消作业时的WaitFor的结果为wrAbandoned（如果没有被取消，则正常返回）
  2015.6.15
  =========
  * 计划作业检查代码的重复作业默认不再初始就创建，只有分配计划任务后才会创建
  * 计划作业检查时间点修改成按分钟对齐（尽量在每分钟的0秒0毫秒触发）
  2015.5.13
  =========
  * 修正了 LookupIdleWorker 连续投递两个任务时，可能未触发两个Worker来处理的问题（LakeView报告）
  2015.4.19
  =========
  * 修正了上次修改解雇算法造成每隔一段时间CPU占用率会上升的问题（恢弘报告）

  2015.4.7
  =========
  + TQJobExtData 加入一个多参数扩展，以方便传递多个参数
  2015.4.6
  =========
  + TQJob 加入 Handle 属性，来反馈自己对应的句柄实例地址（恢弘、音儿小白建议）
  * ClearSingleJob 加入清理时是否等待正在执行过程完成的代码
  * EnumJobState 加入对计划作业的执行
  * 修改句柄标志定义，0,1,2,3分别对应简单作业、重复作业、信号作业和计划作业

  2015.4.2
  =========
  * 修正了 GetTimeTick 函数溢出造成定时作业调度失败的问题（五月报告）
  + 加入 Plan 函数支持计划任务类型的作业（间隔最小为1分钟）

  2015.3.9
  =========
  * 修正了 TQRepeatJobs.DoTimeCompare 比较时间时算术溢出，造成特定应用环境下出错的问题（永不言弃报告）
  2015.2.26
  =========
  * 修正了新增功能在 2007 下无法编译的问题（My Spring 报告）
  * 修正了新增功能在 Android / iOS / OSX 下无法编译的问题（麦子仲肥报告）
  2015.2.24
  =========
  + TQJobGroup 新增 Insert 函数用于插入作业到特定位置（芒果提出需求）
  2015.2.9
  =========
  * 修正了移动平台下作业函数为匿名函数的情况下，重复释放匿名函数指针的问题
  2015.2.3
  =========
  * 修正了在使用 FastMM4 并启用 FullDebugInIDE 模式时，退出时出错的问题（浴火重生报告，青春确认）
  * 修正了 OnError 属性忘记发布的问题

  2015.1.29
  =========
  * 修正了 TQSimpleJobs.Clear 如果第一个就满足需要时算法逻辑出错的问题（KEN报告）
  * 修正了在特定情境下无法及时触发重复作业的问题

  2015.1.28
  =========
  * 修正了 Post / At 重复作业时，如果重复间隔 AInterval 参数值小于 0 时陷入无穷重复的问题

  2015.1.26
  =========
  * 修正了 TQJobGroup.Cancel 取消作业时可能造成等待直到超时的问题（麦子仲肥报告）
  2015.1.15
  =========
  + TQJobGroup 加入全局函数和匿名函数的支持

  2015.1.12
  =========
  + 新增函数 PeekJobState 来获取单个作业的状态信息
  + 新增函数 EnumJobStates 来获取所有作业的状态信息

  2015.1.9
  =========
  * 修正了与 2007的兼容问题,Clear(PIntPtr,ACount)改为名ClearJobs

  2014.12.25
  ==========
  * QWorker的Clear(AHandle:IntPtr)函数改为中ClearSingleJob，以解决在早期Delphi中编译问题（星五）

  2014.12.24
  ==========
  + TQWorkers.Clear加入新的重载，允许一次性清理多个作业句柄（测试中，请谨慎使用，lionet建议)

  2014.12.3
  ==========
  * TQJobGroup.Cancel增加是否等待正在运行的作业结束参数，以避免在作业中直接取消
  分组自身的全部作业时死循环的问题（恢弘）

  2014.11.25
  ==========
  * 修正了WaitSignal函数在在特定情况下，处理延迟作业时未能正确触发的问题

  2014.11.24
  ==========
  * 修正了移动平台下，AData为对象时，由于系统自动管理引用计数，造成对象会自动释放的问题（恢弘报告）
  2014.11.13
  ==========
  + TQJobGroup新增FreeAfterDone属性，当设置为True时，所有作业完成后自动释放对象自身（恢弘建议）
  * 修正了TQJobGroup退出时，存在可能死锁的问题
  * 修正了分组作业未全部完成退出时，没有自动释放造成内存泄露的问题（恢弘报告）

  2014.11.11
  ==========
  * 修改作业返回句柄类型为IntPtr，而不是Int64，在32位平台上能稍快一些（音儿小白、恢弘）

  2014.11.8
  ==========
  * 修正了LongtimeJob在返回值为0时，作业对象被Push两遍的问题（音儿小白）
  * 修正了重复作业设置扩展数据时，首次执行完作业后会被释放的问题（音儿小白）
  * 修正了Assign时，忘记增加引用计数的问题
  * For并行在TQWorkers实例下实现一个内联版本直接调用TQForJobs.For对应的版本
  2014.10.30
  ==========
  * 修改条件编译选项，以兼容2007

  2014.10.28
  ==========
  * 加入条件编译选项，以兼容移动平台(恢弘报告)

  2014.10.27
  ===========
  * 修改作业投寄（Post、At、Delay、LongtimeJob等）的返回值为Int64类型的句柄，用来唯一标
  记一项作业，可以在需要时调用Clear(句柄值)来清除相应的作业（感谢恢弘提出需求）
  * TQJobExtData默认实现了更多基本类型的支持（感谢恢弘提出需求）

  2014.10.26
  ==========
  + 新增面向作业的自定义扩展数据类型对象TQJobExtData以便指定作业的释放过程则不受
  jdfFreeAsC1~jdfFreeAsC6的限制，详细说明参考 http://www.qdac.cc/?p=1018 说明
  （感谢恢弘提出需求）

  2014.10.21
  ==========
  * 默认在移动平台不支持QMapSymbols（恢弘报告）
  * 修正在移动平台上设置TStaticThread优先级失败的问题（恢弘报告)

  2014.10.16
  ===========
  * 修正了由于初始化顺序的原因，造成TStaticThread.CheckNeed函数可能在程序启动时出错的问题（青春报告)
  2014.10.14
  ===========
  * 修正了在特定情况下退出由于TStaticThread访问Workers.FSimpleJobs无效地址造成的问题(音儿小白修复)
  2014.10.11
  ==========
  * 修正了TQJobGroup先投寄作业后Prepare/Run时，重复投寄造成出错的问题（音儿小白报告）
  一般推荐正常顺序为Prepare/Add/Run/Wait。
  * 修正了For循环时匿名函数检测错误

  2014.10.8
  =========
  * 修正了TQJobGroup.Count属性无效的问题（五毒报告）
  * 修正了组作业随时添加（非Prepare/Run）时未正确执行的问题（五毒报告）
  * 修正了由于TSystemTimes定义冲突造成函数无法在XE3、XE4上无法编译的问题（宣言报告）

  2014.9.29
  =========
  + EnumWorkerStatus时，加入了工作者最后一次处理作业的时间参数
  * 修正了在特定情况下超时自动解雇工作者机制不生效的问题（音儿小白报告）
  2014.9.26
  =========
  + 加入后台对CPU利用率的检查，在CPU占用率较低时且有需要立即处理的作业时，启动新工作者
  + 加入EnumWorkerStatus函数来枚举各个作业的状态

  2014.9.23
  =========
  * 修正了未达到工作者线程上限，但已创建的工作者都在工作中时可能造成的延迟问题
  2014.9.14
  =========
  + 增加For循环并发作业支持，访问方式为TQForJobs.For(...)
  * 修改TQJobProc/TQJobProcA/TQJobProcG的写法，以便更方便阅读
  * 修正了TQJobGroup.MsgWaitFor时调用Clear方法时忘记传递参数的问题

  2014.9.12
  =========
  * 修正了多个同一时间点并发的重复作业时可能会死掉的问题（简单生活、厦门小叶报告）

  2014.9.10
  =========
  * 修正了At函数计算跨日期时间差时的算法错误(音儿小白报告并修正）

  2014.9.9
  ========
  * 修正了工作者由于IsIdle检查异步造成投寄的多个作业可能被串行执行的问题（音儿小白报告）
  * 修正了同时清除多个作业时，HasJobRunning由于只判断第一个作业在运行就退出造成
  清理时间过长的问题（音儿小白报告）

  2014.9.1
  =========
  * jdfFreeAsRecord改名为jdfFreeAsSimpleRecord，以提示用户这种类型自动释放的记录只
  适用于简单类型，如果是复杂记录类型的释放，请使用jdfFreeAsC1~jdfFreeAsC6，然后由
  用户自己去响应OnCustomFreeData事件处理(感谢qsl和阿木)，参考Demo里复杂类型释放的
  例子。
  2014.8.30
  =========
  * 修正了工作者在有定时作业时未正正确解雇恢复到保留工作者数量的问题（音儿小白报告）

  2014.8.29
  =========
  * 修正了WaitSignal等待超时时，参数类型错误造成等待超时时间不对的错误(厦门小叶报告)
  2014.8.24
  =========
  * 修改了调度算法，解决原来FBusyCount引入的问题

  2014.8.22
  =========
  * 优化了特定高负载环境下，直接投寄作业处理速度（感谢音儿小白)
  * 修正了FMX下Win32/Win64的兼容问题

  2014.8.21
  =========
  * 修正了TQJobGroup没有正确清理自身超时过程的问题（音儿小白报告）
  + 作业附加的Data释放方式新增jdfFreeAsC1~jdfFreeAsC6以便上层自己管理Data成员数据的自动释放
  + 加入OnCustomFreeData事件，用于上层自己处理Data成员的定制释放问题

  2014.8.19
  =========
  * 修正了TQJob.Synchronize由于inline声明造成在2007下无法正确编译的问题
  * 修正了项目在移动平台编译的问题
  2014.8.18
  =========
  * 修正了合并代码造成LongTimeJob投寄数量限制错误的问题(志文报告）
  * 修正了昨天残留的TQJobGroup.Run函数超时设置出错的问题
  + TQJobGroup增加MsgWaitFor函数，以便在主线程中等待而不阻塞主线程(麦子仲肥测试验证)
  + TQJob增加Synchronize函数，实际上公开的是TThread.Synchronize方法(麦子仲肥测试验证)

  2014.8.17
  =========
  * 改进查找空闲线程机制，以避免不必要开销（感谢音儿小白和笑看红尘)
  * 合并代码，以减少重复代码量（感谢音儿小白）
  * 更改了Wait函数接口，AData和AFreeType参数被取消，改为在信号触发时传递相关参数
  * TQJobGroup.AfterDone改为除了在完成时，在中断或超时时仍然触发
  + TQJobGroup.Add函数加入了AFreeType参数
  + TQJobGroup.Run函数加入超时设置，超过指定的时间如果仍未执行完成，则中止后续执行(Bug出没，请注意未彻底搞定)
  + TQJobGroup.Cancel函数用于取消未执行的作业执行

  2014.8.14
  ==========
  * 参考音儿小白的建议，修改Assign函数，同时TQJobHelper的多个属性改为使用同一个函数实现
  * 修正了在Delphi2007上编译的问题(音儿小白报告并提供修改)
  2014.8.12
  ==========
  * 修正了TQJob.Assign函数忘记复制WorkerProcA成员的问题
  2014.8.8
  ==========
  * 修正了在主线程中Clear时，如果有主线程的作业已投寄到主线程消息队列但尚未执行时
  会出现锁死的问题(playwo报告)

  2014.8.7
  ==========
  * 修正了TQJobGroup添加作业时，忘记修改作业完成状态的问题

  2014.8.2
  ==========
  * 修正了在Windows下DLL中使用QWorker时，由于退出时，线程异常中止时，程序无法退
  出的问题(小李飞刀报告，天地弦验证)
  2014.7.29
  ==========
  + 添加了匿名和全局函数重载形式，在XE5以上版本中，可以支持匿名函数做为作业过程
  [注意]匿名函数不应访问局部变量的值
  2014.7.28
  ==========
  * 修正了ComNeeded函数忘记设置初始化完成标志位的问题(天地弦报告)
  2014.7.21
  ==========
  * 修正了Delphi 2007无法编译的问题

  2014.7.17
  =========
  * 修正了在FMX平台上编译时引用Hint的代码
  2014.7.14
  =========
  * 修正了TQJobGroup没有触发AfterDone事件的问题
  * 修改了引发Hint的代码
  2014.7.12
  =========
  + 添加TQJobGroup支持作业分组
  2014.7.4
  ========
  * 修正了与FMX的兼容性问题(恢弘报告)
  + 加入Clear的清除全部作业的重载实现(D10天地弦建议)
  * 支持在作业过程中通过设置IsTerminated属性来安全结束定时及信号作业
  2014.7.3
  =========
  + MakeJobProc来支持全局作业处理函数
  + TQWorkers.Clear函数增加了两个重载函数，实现清理指定信号关联的全部作业(五毒公主ら。建议)
  * 修正了重复作业正在执行时无法清除干净的问题
  2014.6.26
  =========
  * TEvent.WaitFor加入参数，以解决与Delphi2007的兼容性(D10-天地弦报告)
  * 加入HPPEMIT默认链接本单元(麦子仲肥 建议)
  2014.6.23
  =========
  * 修改了Windows下主线程中作业的触发方式，以改善与COM的兼容性（D10-天地弦报告）
  2014.6.21
  =========
  * 加入了对COM的支持，如果需要在作业中使用COM对象，调用Job.Worker.ComNeeded后即可
  正常访问各个COM对象
  2014.6.19
  =========
  * 修正了DoMainThreadWork函数的参数传递顺序错误
  * 为TQWorker加入了ComNeeded函数，以支持COM的初始化，保障作业内COM相关函数调用
  2014.6.17
  =========
  * 信号触发作业时，加入附加数据成员参数，它将被附加到TQJob结构的Data成员，以便
  上层应用能够做必要的标记，默认值为空
  * 作业投寄时加入了附加的参数，决定如何释放附加的数据对象
}
{$ENDREGION}

uses
  classes, types, sysutils, SyncObjs, Variants, dateutils
{$IFDEF UNICODE}, Generics.Collections{$ENDIF}{$IF RTLVersion>=21},
  Rtti{$IFEND >=XE10}
{$IFNDEF MSWINDOWS}
{$IFNDEF CONSOLE}, fmx.Forms{$ENDIF}, System.Diagnostics
{$ELSE}
{$IFDEF MSWINDOWS}, Windows, Messages, TlHelp32, Activex{$ENDIF}
{$ENDIF}
{$IFDEF POSIX}, Posix.Base, Posix.Unistd, Posix.Signal, Posix.Pthread,
  Posix.Sched, Posix.ErrNo, Posix.SysTypes{$ENDIF}
    , qstring, qrbtree, qtimetypes {$IFDEF ANDROID}, Androidapi.AppGlue,
  Androidapi.Looper, Androidapi.NativeActivity, fmx.Helpers.Android{$ENDIF};
{$HPPEMIT '#pragma link "qworker"'}

{ *QWorker是一个后台工作者管理对象，用于管理线程的调度及运行。在QWorker中，最小的
  工作单位被称为作业（Job），作业可以：
  1、在指定的时间点自动按计划执行，类似于计划任务，只是时钟的分辨率可以更高
  2、在得到相应的信号时，自动执行相应的计划任务
  【限制】
  1.时间间隔由于使用0.1ms为基本单位，因此，64位整数最大值为9223372036224000000，
  除以864000000后就可得结果约为10675199116天，因此，QWorker中的作业延迟和定时重复
  间隔最大为10675199116天。
  2、最少工作者数为1个，无论是在单核心还是多核心机器上，这是最低限制。你可以
  设置的最少工作者数必需大于等于1。工作者上限没做实际限制。
  3、长时间作业数量不得超过最多工作者数量的一半，以免影响正常普通作业的响应。因此
  投寄长时间作业时，应检查投寄结果以确认是否投寄成功
  * }
const
  JOB_RUN_ONCE = $000001; // 作业只运行一次
  JOB_IN_MAINTHREAD = $000002; // 作业只能在主线程中运行
  JOB_MAX_WORKERS = $000004; // 尽可能多的开启可能的工作者线程来处理作业，暂不支持
  JOB_LONGTIME = $000008; // 作业需要很长的时间才能完成，以便调度程序减少它对其它作业的影响
  JOB_SIGNAL_WAKEUP = $000010; // 作业根据信号需要唤醒
  JOB_TERMINATED = $000020; // 作业不需要继续进行，可以结束了
  JOB_GROUPED = $000040; // 当前作业是作业组的一员
  JOB_ANONPROC = $000080; // 当前作业过程是匿名函数
  JOB_FREE_OBJECT = $000100; // Data关联的是Object，作业完成或清理时释放
  JOB_FREE_RECORD = $000200; // Data关联的是Record，作业完成或清理时释放
  JOB_FREE_INTERFACE = $000300; // Data关联的是Interface，作业完成时调用_Release
  JOB_FREE_CUSTOM1 = $000400; // Data关联的成员由用户指定的方式1释放
  JOB_FREE_CUSTOM2 = $000500; // Data关联的成员由用户指定的方式2释放
  JOB_FREE_CUSTOM3 = $000600; // Data关联的成员由用户指定的方式3释放
  JOB_FREE_CUSTOM4 = $000700; // Data关联的成员由用户指定的方式4释放
  JOB_FREE_CUSTOM5 = $000800; // Data关联的成员由用户指定的方式5释放
  JOB_FREE_CUSTOM6 = $000900; // Data关联的成员由用户指定的方式6释放
  JOB_BY_PLAN = $001000; // 作业的Interval是一个TQPlanMask的掩码值
  JOB_DELAY_REPEAT = $002000; // 作业是定间隔的延迟作业，在上一次完成后，才会计算下次间隔时间
  JOB_DATA_OWNER = $000F00; // 作业是Data成员的所有者
  JOB_HANDLE_SIMPLE_MASK = $00;
  JOB_HANDLE_REPEAT_MASK = $01;
  JOB_HANDLE_SIGNAL_MASK = $02;
  JOB_HANDLE_PLAN_MASK = $03;

  WORKER_ISBUSY = $0001; // 工作者忙碌
  WORKER_PROCESSLONG = $0002; // 当前处理的一个长时间作业
  WORKER_COM_INITED = $0004; // 工作者已初始化为支持COM的状态(仅限Windows)
  WORKER_LOOKUP = $0008; // 工作者正在查找作业
  WORKER_EXECUTING = $0010; // 工作者正在执行作业
  WORKER_EXECUTED = $0020; // 工作者已经完成作业
  WORKER_FIRING = $0040; // 工作者正在被解雇
  WORKER_RUNNING = $0080; // 工作者线程已经开始运行
  WORKER_CLEANING = $0100; // 工作者线程正在清理作业
  DEFAULT_FIRE_TIMEOUT = 15000;
  INVALID_JOB_DATA = Pointer(-1);
  Q1MillSecond = 10; // 1ms
  Q1Second = 10000; // 1s
  Q1Minute = 600000; // 60s/1min
  Q1Hour = 36000000; // 3600s/60min/1hour
  Q1Day = Int64(864000000); // 1day
{$IFNDEF UNICODE}
  wrIOCompletion = TWaitResult(4);
{$ENDIF}

type
  TQJobs = class;
  TQWorker = class;
  TQWorkers = class;
  TQJobGroup = class;
  TQForJobs = class;
  PQSignal = ^TQSignal;
  PQJob = ^TQJob;
  /// <summary>作业处理回调函数</summary>
  /// <param name="AJob">要处理的作业信息</param>
  TQJobProc = procedure(AJob: PQJob) of object;
  PQJobProc = ^TQJobProc;
  TQJobProcG = procedure(AJob: PQJob);
  TQForJobProc = procedure(ALoopMgr: TQForJobs; AJob: PQJob; AIndex: NativeInt)
    of object;
  PQForJobProc = ^TQForJobProc;
  TQForJobProcG = procedure(ALoopMgr: TQForJobs; AJob: PQJob;
    AIndex: NativeInt);
{$IFDEF UNICODE}
  TQJobProcA = reference to procedure(AJob: PQJob);
  TQForJobProcA = reference to procedure(ALoopMgr: TQForJobs; AJob: PQJob;
    AIndex: NativeInt);
{$ENDIF}
  /// <summary>作业空闲原因，内部使用</summary>
  /// <remarks>
  /// irNoJob : 没有需要处理的作业，此时工作者会进入释放等待状态，如果在等待时间内
  /// 有新作业进来，则工作者会被唤醒，否则超时后会被释放
  /// irTimeout : 工作者已经等待超时，可以被释放
  TWorkerIdleReason = (irNoJob, irTimeout);

  /// <summary>作业结束时如何处理Data成员</summary>
  /// <remarks>
  /// jdoFreeByUser : 用户管理对象的释放
  /// jdoFreeAsObject : 附加的是一个TObject继承的对象，作业完成时会调用FreeObject释放
  /// jdfFreeAsSimpleRecord : 附加的是一个记录（结构体），作业完成时会调用Dispose释放
  /// 注意由于释放时实际上是FreeMem，此结构体不应包含复杂类型，如String/动态数组/Variant等需要
  /// jdtFreeAsInterface : 附加的是一个接口对象，添加时会增加计数，作业完成时会减少计数
  /// jdfFreeAsC1 : 用户自行指定的释放方法1
  /// jdfFreeAsC2 : 用户自行指定的释放方法2
  /// jdfFreeAsC3 : 用户自行指定的释放方法3
  /// jdfFreeAsC4 : 用户自行指定的释放方法4
  /// jdfFreeAsC5 : 自户自行指定的释放方法5
  /// jdfFreeAsC6 : 用户自行指定的释放方法6
  /// </remarks>
  TQJobDataFreeType = (jdfFreeByUser, jdfFreeAsObject, jdfFreeAsSimpleRecord,
    jdfFreeAsInterface, jdfFreeAsC1, jdfFreeAsC2, jdfFreeAsC3, jdfFreeAsC4,
    jdfFreeAsC5, jdfFreeAsC6);

  TQRunonceTask = record
    CanRun: Integer;
{$IFDEF UNICODE}
    procedure Runonce(ACallback: TProc); overload;
{$ENDIF}
    procedure Runonce(ACallback: TProcedure); overload;
    procedure Runonce(ACallback: TThreadMethod); overload;
  end;

  TQJobPlanData = record
    NextTime: TDateTime;
    OriginData: Pointer;
    Runnings: Integer;
    Plan: TQPlanMask;
    DataFreeType: TQJobDataFreeType;
  end;

  PQJobPlanData = ^TQJobPlanData;

  TQExtFreeEvent = procedure(AData: Pointer) of object;
  TQExtInitEvent = procedure(var AData: Pointer) of Object;
{$IFDEF UNICODE}
  TQExtInitEventA = reference to procedure(var AData: Pointer);
  TQExtFreeEventA = reference to procedure(AData: Pointer);
{$ENDIF}

  TQJobExtData = class
  private
    function GetAsBoolean: Boolean;
    function GetAsDouble: Double;
    function GetAsInteger: Integer;
    function GetAsString: QStringW;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsDouble(const Value: Double);
    procedure SetAsInteger(const Value: Integer);
    procedure SetAsString(const Value: QStringW);
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(const Value: TDateTime);
    function GetAsInt64: Int64;
    procedure SetAsInt64(const Value: Int64);
    function GetAsPlan: PQJobPlanData;
    function GetParamCount: Integer;
    function GetParams(AIndex: Integer): Variant;
  protected
    FOrigin: Pointer;
    FOnFree: TQExtFreeEvent;
{$IFDEF UNICODE}
    FOnFreeA: TQExtFreeEventA;
{$ENDIF}
    procedure DoFreeAsString(AData: Pointer);
    procedure DoSimpleTypeFree(AData: Pointer);
    procedure DoFreeAsPlan(AData: Pointer);
    procedure DoFreeAsVariant(AData: Pointer);
{$IFNDEF NEXTGEN}
    function GetAsAnsiString: AnsiString;
    procedure SetAsAnsiString(const Value: AnsiString);
    procedure DoFreeAsAnsiString(AData: Pointer);
{$ENDIF}
  public
    constructor Create(AData: Pointer; AOnFree: TQExtFreeEvent); overload;
    constructor Create(AOnInit: TQExtInitEvent;
      AOnFree: TQExtFreeEvent); overload;
    constructor Create(const APlan: TQPlanMask; AData: Pointer;
      AFreeType: TQJobDataFreeType); overload;
    constructor Create(const AParams: array of const); overload;
{$IFDEF UNICODE}
    constructor Create(AData: Pointer; AOnFree: TQExtFreeEventA); overload;
    constructor Create(AOnInit: TQExtInitEventA;
      AOnFree: TQExtFreeEventA); overload;
{$ENDIF}
    constructor Create(const Value: Int64); overload;
    constructor Create(const Value: Integer); overload;
    constructor Create(const Value: Boolean); overload;
    constructor Create(const Value: Double); overload;
    constructor CreateAsDateTime(const Value: TDateTime); overload;
    constructor Create(const S: QStringW); overload;
{$IFNDEF NEXTGEN}
    constructor Create(const S: AnsiString); overload;
{$ENDIF}
    destructor Destroy; override;
    property Origin: Pointer read FOrigin;
    property AsString: QStringW read GetAsString write SetAsString;
{$IFNDEF NEXTGEN}
    property AsAnsiString: AnsiString read GetAsAnsiString
      write SetAsAnsiString;
{$ENDIF}
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsFloat: Double read GetAsDouble write SetAsDouble;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsPlan: PQJobPlanData read GetAsPlan;
    property Params[AIndex: Integer]: Variant read GetParams;
    property ParamCount: Integer read GetParamCount;
  end;

  TQJobMethod = record
    case Integer of
      0:
        (Proc: {$IFNDEF NEXTGEN}TQJobProc{$ELSE}Pointer{$ENDIF});
      1:
        (ProcG: TQJobProcG);
      2:
        (ProcA: Pointer);
      3:
        (ForProc: {$IFNDEF NEXTGEN}TQForJobProc{$ELSE}Pointer{$ENDIF});
      4:
        (ForProcG: TQForJobProcG);
      5:
        (ForProcA: Pointer);
      6:
        (Code: Pointer; Data: Pointer);
      7:
        (Method: TMethod);
  end;

  TQJob = record
  private
    function GetAvgTime: Integer; inline;
    function GetElapsedTime: Int64; inline;
    function GetIsTerminated: Boolean; inline;
    function GetFlags(AIndex: Integer): Boolean; inline;
    procedure SetFlags(AIndex: Integer; AValue: Boolean); inline;
    procedure UpdateNextTime;
    procedure SetIsTerminated(const Value: Boolean);
    procedure AfterRun(AUsedTime: Int64);
    function GetFreeType: TQJobDataFreeType; inline;
    function GetIsCustomFree: Boolean; inline;
    function GetIsObjectOwner: Boolean; inline;
    function GetIsRecordOwner: Boolean; inline;
    function GetIsInterfaceOwner: Boolean; inline;
    function GetExtData: TQJobExtData; inline;
    procedure SetFreeType(const Value: TQJobDataFreeType);
    function GetHandle: IntPtr;
    function GetIsPlanRunning: Boolean;
    function GetIsAnonWorkerProc: Boolean;
  public
    constructor Create(AProc: TQJobProc); overload;
    /// <summary>值拷贝函数</summary>
    /// <remarks>Worker/Next/Source不会复制并会被置空，Owner不会被复制</remarks>
    procedure Assign(const ASource: PQJob);
    /// <summary>重置内容，以便为从队列中弹出做准备</summary>
    procedure Reset; inline;

    /// <summary>公开下线程对象的同步方法，但更推荐投寄异步作业到主线程中处理</summary>
    procedure Synchronize(AMethod: TThreadMethod); overload;
{$IFDEF UNICODE}inline; {$ENDIF}
{$IFDEF UNICODE}
    procedure Synchronize(AProc: TThreadProcedure); overload; inline;
{$ENDIF}
    /// <summary>平均每次运行时间，单位为0.1ms</summary>
    property AvgTime: Integer read GetAvgTime;
    /// <summmary>本次已运行时间，单位为0.1ms</summary>
    property ElapsedTime: Int64 read GetElapsedTime;
    /// <summary>是否只运行一次，投递作业时自动设置</summary>
    property Runonce: Boolean index JOB_RUN_ONCE read GetFlags;
    /// <summary>是否要求在主线程执行作业，实际效果和 Windows 的 PostMessage 相似</summary>
    property InMainThread: Boolean index JOB_IN_MAINTHREAD read GetFlags;
    /// <summary>是否是一个运行时间比较长的作业，用Workers.LongtimeWork设置</summary>
    property IsLongtimeJob: Boolean index JOB_LONGTIME read GetFlags;
    /// <summary>是否是一个信号触发的作业</summary>
    property IsSignalWakeup: Boolean index JOB_SIGNAL_WAKEUP read GetFlags;
    /// <summary>是否是分组作业的成员</summary>
    property IsGrouped: Boolean index JOB_GROUPED read GetFlags;
    /// <summary>是否要求结束当前作业</summary>
    property IsTerminated: Boolean read GetIsTerminated write SetIsTerminated;
    /// <summary>判断作业的Data指向的是一个对象且要求作业完成时自动释放</summary>
    property IsObjectOwner: Boolean read GetIsObjectOwner;
    /// <summary>判断作业的Data指向的是一个记录且要求作业完成时自动释放</summary>
    property IsRecordOwner: Boolean read GetIsRecordOwner;
    /// <summary>判断作业的Data是否是由用户所指定的方法自动释放</summary>
    property IsCustomFree: Boolean read GetIsCustomFree;
    property FreeType: TQJobDataFreeType read GetFreeType write SetFreeType;
    /// <summary>判断作业是否拥有Data数据成员
    property IsDataOwner: Boolean index JOB_DATA_OWNER read GetFlags;
    /// <summary>判断作业的Data指向的是一个接口且要求作业完成时自动释放</summary>
    property IsInterfaceOwner: Boolean read GetIsInterfaceOwner;
    /// <summary>判断作业处理过程是否是一个匿名函数</summary>
    property IsAnonWorkerProc: Boolean read GetIsAnonWorkerProc;
    /// <summary>作业是由一个计划任务触发</summary>
    property IsByPlan: Boolean index JOB_BY_PLAN read GetFlags write SetFlags;
    /// <summary>扩展的作业处理过程数据</summary>
    property ExtData: TQJobExtData read GetExtData;
    /// <summary>计划任务作业是否在执行中</summary>
    property IsPlanRunning: Boolean read GetIsPlanRunning;
    /// <summary>是否是延迟重复作业</summary>
    property IsDelayRepeat: Boolean index JOB_DELAY_REPEAT read GetFlags
      write SetFlags;
    /// <summary>作业对象的句柄</summary>
    property Handle: IntPtr read GetHandle;
  public
    FirstStartTime: Int64; // 作业第一次开始时间
    StartTime: Int64; // 本次作业开始时间,8B
    PushTime: Int64; // 入队时间
    PopTime: Int64; // 出队时间
    DoneTime: Int64; // 作业结束时间
    NextTime: Int64; // 下一次运行的时间,+8B=16B
    WorkerProc: TQJobMethod; //
    Owner: TQJobs; // 作业所隶属的队列
    Next: PQJob; // 下一个结点
    Worker: TQWorker; // 当前作业工作者
    Runs: Integer; // 已经运行的次数+4B
    MinUsedTime: Cardinal; // 最小运行时间+4B
    TotalUsedTime: Cardinal; // 运行总计花费的时间，TotalUsedTime/Runs可以得出平均执行时间+4B
    MaxUsedTime: Cardinal; // 最大运行时间+4B
    Flags: Integer; // 作业标志位+4B
    Data: Pointer; // 附加数据内容
    case Integer of
      0:
        (SignalData: Pointer; // 信号触发的相关数据，TQSignalQueueItem类型
        );
      1:
        (Interval: Int64; // 运行时间间隔，单位为0.1ms，实际精度受不同操作系统限制+8B
          FirstDelay: Int64; // 首次运行延迟，单位为0.1ms，默认为0
          Source: PQJob;
        );
      2: // 分组作业支持
        (Group: Pointer;
        );
      3:
        (PlanJob: Pointer;
        );
  end;

  /// <summary>作业状态，由PeekJobState函数返回</summary>
  TQJobState = record
    Handle: IntPtr; // 作业对象句柄
    Proc: TQJobMethod; // 作业过程
    Flags: Integer; // 标志位
    IsRunning: Boolean; // 是否在运行中，如果为False，则作业处于队列中
    Runs: Integer; // 已经运行的次数
    EscapedTime: Int64; // 已经执行时间
    PushTime: Int64; // 入队时间
    PopTime: Int64; // 出队时间
    AvgTime: Int64; // 平均时间
    TotalTime: Int64; // 总执行时间
    MaxTime: Int64; // 最大执行时间
    MinTime: Int64; // 最小执行时间
    NextTime: Int64; // 重复作业的下次执行时间
    Plan: TQPlanMask; // 计划任务设置
  end;

  TQJobStateArray = array of TQJobState;

  PQJobWaitChain = ^TQJobWaitChain;

  TQJobWaitChain = record
    Job: IntPtr;
    Event: Pointer;
    Prior: PQJobWaitChain;
  end;

  /// <summary>工作者记录的辅助函数</summary>
  // TQJobHelper = record helper for TQJob
  //
  // end;

  // 作业队列对象的基类，提供基础的接口封装
  TQJobs = class
  protected
    FOwner: TQWorkers;
    function InternalPush(AJob: PQJob): Boolean; virtual; abstract;
    function InternalPop: PQJob; virtual; abstract;
    function GetCount: Integer; virtual; abstract;
    function GetEmpty: Boolean;
    /// <summary>投寄一个作业</summary>
    /// <param name="AJob">要投寄的作业</param>
    /// <remarks>外部不应尝试直接投寄任务到队列，其由TQWorkers的相应函数内部调用。</remarks>
    function Push(AJob: PQJob): Boolean; virtual;
    /// <summary>弹出一个作业</summary>
    /// <returns>返回当前可以执行的第一个作业</returns>
    function Pop: PQJob; virtual;
    /// <summary>清空所有作业</summary>
    procedure Clear; overload; virtual;
    /// <summary>清空指定的作业</summary>
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer)
      : Integer; overload; virtual; abstract;
    /// <summary>清空一个对象关联的所有作业</summary>
    function Clear(AObject: Pointer; AMaxTimes: Integer): Integer; overload;
      virtual; abstract;
    /// <summary>根据句柄清除一个作业对象</summary>
    function Clear(AHandle: IntPtr): Boolean; overload; virtual;
    /// <summary>根据句柄列表清除一组作业对象</summary>
    function ClearJobs(AHandes: PIntPtr; ACount: Integer): Integer; overload;
      virtual; abstract;
  public
    constructor Create(AOwner: TQWorkers); overload; virtual;
    destructor Destroy; override;
    /// 不可靠警告：Count和Empty值仅是一个参考，在多线程环境下可能并不保证下一句代码执行时，会一致
    property Empty: Boolean read GetEmpty; // 当前队列是否为空
    property Count: Integer read GetCount; // 当前队列元素数量
  end;

  TQSimpleLock = TCriticalSection;

  // TQSimpleJobs用于管理简单的异步调用，没有触发时间要求的作业
  TQSimpleJobs = class(TQJobs)
  protected
    FFirst, FLast: PQJob;
    FCount: Integer;
    FLocker: TQSimpleLock;
    function InternalPush(AJob: PQJob): Boolean; override;
    function InternalPop: PQJob; override;
    function GetCount: Integer; override;
    procedure Clear; overload; override;
    function Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
      overload; override;
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer)
      : Integer; overload; override;
    function Clear(AHandle: IntPtr): Boolean; overload; override;
    function ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
      overload; override;
    function PopAll: PQJob; inline;
    procedure Repush(ANewFirst: PQJob);
  public
    constructor Create(AOwner: TQWorkers); override;
    destructor Destroy; override;
  end;

  // TQRepeatJobs用于管理计划型任务，需要在指定的时间点触发
  TQRepeatJobs = class(TQJobs)
  protected
    FItems: TQRBTree;
    FLocker: TCriticalSection;
    FFirstFireTime: Int64;
    function InternalPush(AJob: PQJob): Boolean; override;
    function InternalPop: PQJob; override;
    function DoTimeCompare(P1, P2: Pointer): Integer;
    procedure DoJobDelete(ATree: TQRBTree; ANode: TQRBNode);
    function GetCount: Integer; override;
    procedure Clear; override;
    function Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
      overload; override;
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer)
      : Integer; overload; override;
    function Clear(AHandle: IntPtr): Boolean; overload; override;
    function ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
      overload; override;
    procedure AfterJobRun(AJob: PQJob; AUsedTime: Int64);
  public
    constructor Create(AOwner: TQWorkers); override;
    destructor Destroy; override;
  end;

  PQSignalQueueItem = ^TQSignalQueueItem;

  TQSignalQueueItem = record
    Id: Integer; // 要触发的信号ID
    Data: Pointer; // 触发信号时传递的 Data 的值
    RefCount: Integer; // 引用计数
    FireCount: Integer; // 触发中的作业数
    FreeType: TQJobDataFreeType; // 触发信号时传递的释放方式
    WaitEvent: Pointer; // 等待处理完成的事件
    Next: PQSignalQueueItem; // 下一个要触发的信号
  end;

  TQSignalQueue = class
  protected
    FFirst, FLast: PQSignalQueueItem; // 队列中的首末元素
    FCount: Integer; // 队列中的元素个数
    FMaxItems: Integer; // 队列中允许的最大排队的信号数量
    FLocker: TQSimpleLock; // 同步锁
    FOwner: TQWorkers; // 队列所有者
    FLastPop: Pointer; // 最后弹出的信号
    procedure Clear;
    function InternalPost(AItem: PQSignalQueueItem): Boolean;
    function NewItem(AId: Integer; AData: Pointer; AFreeType: TQJobDataFreeType;
      AWaiter: TEvent): PQSignalQueueItem;
    procedure FreeItem(AItem: PQSignalQueueItem);
    procedure FireNext;
    procedure SingalJobDone(AItem: PQSignalQueueItem);
  public
    constructor Create(AOwner: TQWorkers); overload;
    destructor Destroy; override;
    function Post(AId: Integer; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    function Post(AName: QStringW; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    function Send(AId: Integer; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser;
      ATimeout: Cardinal = INFINITE): TWaitResult; overload;
    function Send(AName: QStringW; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser;
      ATimeout: Cardinal = INFINITE): TWaitResult; overload;
    property MaxItems: Integer read FMaxItems write FMaxItems;
    property Count: Integer read FCount;
  end;

  //
  TQWorkerExtClass = class of TQWorkerExt;

  TQWorkerExt = class
  protected
    FOwner: TQWorker;
  public
    constructor Create(AOwner: TQWorker); overload; virtual;
    property Owner: TQWorker read FOwner;
  end;

  { 工作者线程使用数组管理，而不是进行排序检索是因为对于工作者数量有限，额外
    的处理反而不会直接最简单的循环直接有效
  }
  TQWorker = class(TThread)
  private

  protected
    FOwner: TQWorkers;
    FEvent: TEvent;
    FTimeout: Cardinal;
    FFireDelay: Cardinal;
    FFlags: Integer;
    FProcessed: Cardinal;
    FActiveJobFlags: Integer;
    FActiveJob: PQJob;
    // 之所以不直接使用FActiveJob的相关方法，是因为保证外部可以线程安全的访问这两个成员
    FActiveJobProc: TQJobMethod;
    FActiveJobData: Pointer;
    FActiveJobSource: PQJob;
    FActiveJobGroup: TQJobGroup;
    FTerminatingJob: PQJob;
    FLastActiveTime: Int64;
    FPending: Boolean; // 已经计划作业
    FTag: IntPtr;
    FExtObject: TQWorkerExt;
{$IFDEF MSWINDOWS}
    FThreadName: String;
{$ENDIF}
    procedure Execute; override;
    procedure AfterExecute;
    procedure FireInMainThread;
    procedure DoJob(AJob: PQJob);
    function GetExtObject: TQWorkerExt;
    function GetIsIdle: Boolean; inline;
    procedure SetFlags(AIndex: Integer; AValue: Boolean); inline;
    function GetFlags(AIndex: Integer): Boolean; inline;
    function WaitSignal(ATimeout: Cardinal; AByRepeatJob: Boolean)
      : TWaitResult; inline;
  public
    constructor Create(AOwner: TQWorkers); overload;
    destructor Destroy; override;
    procedure ComNeeded(AInitFlags: Cardinal = 0);
    procedure ForceQuit;
    /// <summary>判断当前是否处于长时间作业处理过程中</summary>
    property InLongtimeJob: Boolean index WORKER_PROCESSLONG read GetFlags;
    /// <summary>判断当前是否空闲</summary>
    property IsIdle: Boolean read GetIsIdle;
    /// <summary>判断当前是否忙碌</summary>
    property IsBusy: Boolean index WORKER_ISBUSY read GetFlags;
    property IsLookuping: Boolean index WORKER_LOOKUP read GetFlags;
    property IsExecuting: Boolean index WORKER_EXECUTING read GetFlags;
    property IsExecuted: Boolean index WORKER_EXECUTED read GetFlags;
    property IsFiring: Boolean index WORKER_FIRING read GetFlags;
    property IsRunning: Boolean index WORKER_RUNNING read GetFlags;
    property IsCleaning: Boolean index WORKER_CLEANING read GetFlags;
    /// <summary>判断COM是否已经初始化为支持COM
    property ComInitialized: Boolean index WORKER_COM_INITED read GetFlags;
    property ExtObject: TQWorkerExt read GetExtObject;
    property Tag: IntPtr read FTag write FTag;
  end;

  /// <summary>信号的内部定义</summary>
  TQSignal = record
    Id: Integer;
    /// <summary>信号的编码</summary>
    Fired: Integer; // <summary>信号已触发次数</summary>
    Name: QStringW;
    /// <summary>信号的名称</summary>
    First: PQJob;
    /// <summary>首个作业</summary>
  end;

  TWorkerWaitParam = record
    WaitType: Byte;
    Data: Pointer;
    case Integer of
      0:
        (Bound: Pointer); // 按对象清除
      1:
        (WorkerProc: TMethod;);
      2:
        (SourceJob: PQJob);
      3:
        (Group: Pointer);
  end;
  /// <summary>错误来源，可取值包括：
  /// jesExecute : 执行时出错
  /// jesFreeData : 释放附加数据时出错
  /// jesWaitDone : 在等待作业完成时出错
  /// </summary>

  TJobErrorSource = (jesExecute, jesFreeData, jesWaitDone);
  // For并发的索引值类型
  TForLoopIndexType = {$IF RTLVersion>=26}NativeInt{$ELSE}Integer{$IFEND};
  /// <summary>工作者错误通知事件</summary>
  /// <param name="AJob">发生错误的作业对象</param>
  /// <param name="E">发生错误异常对象</param>
  /// <param name="ErrSource">错误来源</param>
  TWorkerErrorNotify = procedure(AJob: PQJob; E: Exception;
    const ErrSource: TJobErrorSource) of object;
  // 自定义数据释放事件
  TQCustomFreeDataEvent = procedure(ASender: TQWorkers;
    AFreeType: TQJobDataFreeType; const AData: Pointer);
  TQJobNotifyEvent = procedure(AJob: PQJob);

  TQWorkerStatusItem = record
    LastActive: Int64;
    Processed: Cardinal;
    ThreadId: TThreadId;
    IsIdle: Boolean;
    ActiveJob: QStringW;
    Stacks: QStringW;
    Timeout: Cardinal;
  end;

  TQWorkerStatus = array of TQWorkerStatusItem;

  /// <summary>工作者管理对象，用来管理工作者和作业</summary>
  TQWorkers = class
  private
    function GetTerminating: Boolean;
  protected
    FWorkers: array of TQWorker; // 工作者数组
    FDisableCount: Integer;
    // DisableWorkers 的调用次数，必需与 EnableWorkers 来匹配，否则作业将无法执行
    FMinWorkers: Integer; // 最小工作者数量
    FMaxWorkers: Integer; // 最大工作者数量
    FWorkerCount: Integer; // 当前工作者总数
    FBusyCount: Integer; // 当前活动工作者数
    FFiringWorkerCount: Integer; // 当前正在解雇中的工作者数量
    FFireTimeout: Cardinal; // 工作者解雇的基准超时（最小时间），单位毫秒
    FLongTimeWorkers: Integer; // 记录下长时间作业中的工作者，这种任务长时间不释放资源，可能会造成其它任务无法及时响应
    FMaxLongtimeWorkers: Integer; // 允许最多同时执行的长时间任务数，不允许超过MaxWorkers的一半
    FLocker: TCriticalSection; // 锁
    FSimpleJobs: TQSimpleJobs; // 简单作业列表
    FPlanJobs: TQSimpleJobs; // 计划任务，会每秒钟检查一次其中是否有需要执行的作业
    FRepeatJobs: TQRepeatJobs; // 重复作业列表
    FSignalJobs: array of PQSignal; // 信号作业数组，每个信号维护独立的作业列表
    FSignalNameList: TList; // 按名称索引的信号列表以优化按名称访问效率
    FMaxSignalId: Integer; // 当前最大信号的Id
    FTerminating: Boolean; // 是否正在结束中
    FStaticThread: TThread; // 后台监控统计线程
    FPlanCheckJob: IntPtr; // 计划任务检查作业
    FOnError: TWorkerErrorNotify; // 出错时处理事件
    FBeforeExecute: TQJobNotifyEvent; // 作业执行前触发事件
    FAfterExecute: TQJobNotifyEvent; // 作业执行完触发事件
    FBeforeCancel: TQJobNotifyEvent; // 作业取消前触发事件
    FLastWaitChain: PQJobWaitChain; // 作业等待链表
    FSignalQueue: TQSignalQueue; // 信号作业调度管理器
    FOnCustomFreeData: TQCustomFreeDataEvent; // 自定义的释放数据回调函数
    FWorkerExtClass: TQWorkerExtClass;
    FTerminateEvent: TEvent; // 退出时等待工作者结束事件
{$IFDEF MSWINDOWS}
    FMainWorker: HWND; // 用于接收主线程作业的窗口（目前仅调试模式下用）
    procedure DoMainThreadWork(var AMsg: TMessage); // FMainWorker 的消息处理函数
{$ENDIF}
    function Popup: PQJob;
    procedure SetMaxWorkers(const Value: Integer);
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
    procedure SetMinWorkers(const Value: Integer);
    procedure WorkerTimeout(AWorker: TQWorker); inline;
    procedure WorkerTerminate(AWorker: TQWorker);
    procedure FreeJob(AJob: PQJob);
    function LookupIdleWorker(AFromStatic: Boolean): Boolean;
    procedure ClearWorkers;
    procedure SignalWorkDone(AJob: PQJob; AUsedTime: Int64);
    procedure DoJobFree(ATable: TQHashTable; AHash: Cardinal; AData: Pointer);
    function Post(AJob: PQJob): IntPtr; overload;
    procedure SetMaxLongtimeWorkers(const Value: Integer);
    function FindSignal(const AName: QStringW; var AIndex: Integer): Boolean;
    procedure FireSignalJob(AData: PQSignalQueueItem);
    function ClearSignalJobs(ASource: PQJob;
      AWaitRunningDone: Boolean = True): Integer;
    procedure WaitSignalJobsDone(AJob: PQJob);
    procedure WaitRunningDone(const AParam: TWorkerWaitParam;
      AMarkTerminateOnly: Boolean = false);
    procedure FreeJobData(AData: Pointer; AFreeType: TQJobDataFreeType);
    procedure DoCustomFreeData(AFreeType: TQJobDataFreeType;
      const AData: Pointer);
    function GetIdleWorkers: Integer; inline;
    function GetBusyCount: Integer; inline;
    function GetOutWorkers: Boolean; inline;
    procedure SetFireTimeout(const Value: Cardinal);
    procedure ValidWorkers; inline;
    procedure NewWorkerNeeded;
    function CreateWorker(ASuspended: Boolean): TQWorker;
    function GetNextRepeatJobTime: Int64; inline;
    procedure DoPlanCheck(AJob: PQJob);
    procedure AfterPlanRun(AJob: PQJob; AUsedTime: Int64);
    function HandleToJob(const AHandle: IntPtr): PQJob; inline;
    procedure PlanCheckNeeded;
    procedure CheckWaitChain(AJob: PQJob);
  public
    constructor Create(AMinWorkers: Integer = 2); overload;
    destructor Destroy; override;
    /// <summary>投寄一个后台立即开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProc; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个后台立即开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcG; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个后台立即开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcA; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个后台定时开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要定时执行的作业时间间隔，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProc; AInterval: Int64; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个后台定时开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要定时执行的作业时间间隔，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcG; AInterval: Int64; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;

{$IFDEF UNICODE}
    /// <summary>投寄一个后台定时开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要定时执行的作业时间间隔，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcA; AInterval: Int64; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个延迟开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ADelay">要延迟的时间，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <param name="ARepeat">是否在上一次作业完成后，再次延迟</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Delay(AProc: TQJobProc; ADelay: Int64; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser; ARepeat: Boolean = false)
      : IntPtr; overload;
    /// <summary>投寄一个延迟开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ADelay">要延迟的时间，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <param name="ARepeat">是否在上一次作业完成后，再次延迟</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Delay(AProc: TQJobProcG; ADelay: Int64; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser; ARepeat: Boolean = false)
      : IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个延迟开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ADelay">要延迟的时间，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <param name="ARepeat">是否在上一次作业完成后，再次延迟</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Delay(AProc: TQJobProcA; ADelay: Int64; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser; ARepeat: Boolean = false)
      : IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个等待信号才开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ASignalId">等待的信号编码，该编码由RegisterSignal函数返回</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Wait(AProc: TQJobProc; ASignalId: Integer;
      ARunInMainThread: Boolean = false; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    function Wait(AProc: TQJobProc; const ASignalName: QStringW;
      ARunInMainThread: Boolean = false; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个等待信号才开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ASignalId">等待的信号编码，该编码由RegisterSignal函数返回</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Wait(AProc: TQJobProcG; ASignalId: Integer;
      ARunInMainThread: Boolean = false; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    function Wait(AProc: TQJobProcG; const ASignalName: QStringW;
      ARunInMainThread: Boolean = false; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个等待信号才开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ASignalId">等待的信号编码，该编码由RegisterSignal函数返回</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Wait(AProc: TQJobProcA; ASignalId: Integer;
      ARunInMainThread: Boolean = false; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    function Wait(AProc: TQJobProcA; const ASignalName: QStringW;
      ARunInMainThread: Boolean = false; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ADelay">第一次执行前先延迟时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProc; const ADelay, AInterval: Int64;
      AData: Pointer; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ADelay">第一次执行前先延迟时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcG; const ADelay, AInterval: Int64;
      AData: Pointer; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ADelay">第一次执行前先延迟时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcA; const ADelay, AInterval: Int64;
      AData: Pointer; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ATime">执行时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProc; const ATime: TDateTime;
      const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ATime">执行时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcG; const ATime: TDateTime;
      const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ATime">执行时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcA; const ATime: TDateTime;
      const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个计划任务作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="APlan">要执行的计划任务设置</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Plan(AProc: TQJobProc; const APlan: TQPlanMask; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个计划任务作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="APlan">要执行的计划任务设置</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Plan(AProc: TQJobProc; const APlan: QStringW; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个计划任务作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="APlan">要执行的计划任务设置</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Plan(AProc: TQJobProcG; const APlan: TQPlanMask; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个计划任务作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="APlan">要执行的计划任务设置</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Plan(AProc: TQJobProcG; const APlan: QStringW; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个计划任务作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="APlan">要执行的计划任务设置</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Plan(AProc: TQJobProcA; const APlan: TQPlanMask; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个计划任务作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="APlan">要执行的计划任务设置</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Plan(AProc: TQJobProcA; const APlan: QStringW; AData: Pointer;
      ARunInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个后台长时间执行的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回True，否则返回False</returns>
    /// <remarks>长时间作业强制在后台线程中执行，而不允许投递到主线程中执行</remarks>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function LongtimeJob(AProc: TQJobProc; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个后台长时间执行的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <returns>成功投寄返回True，否则返回False</returns>
    /// <remarks>长时间作业强制在后台线程中执行，而不允许投递到主线程中执行</remarks>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function LongtimeJob(AProc: TQJobProcG; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个后台长时间执行的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回True，否则返回False</returns>
    /// <remarks>长时间作业强制在后台线程中执行，而不允许投递到主线程中执行</remarks>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function LongtimeJob(AProc: TQJobProcA; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>清除所有作业</summary>
    /// <param name="AWaitRunningDone">是否等待正在运行的作业完成，默认为 true 等待</param>
    procedure Clear(AWaitRunningDone: Boolean = True); overload;
    /// <summary>清除一个对象相关的所有作业</summary>
    /// <param name="AObject">要释放的作业处理过程关联对象</param>
    /// <param name="AMaxTimes">最多清除的数量，如果<0，则全清</param>
    /// <returns>返回实际清除的作业数量</returns>
    /// <param name="AWaitRunningDone">是否等待正在运行的作业完成，默认为 true 等待</param>
    /// <remarks>一个对象如果计划了作业，则在自己释放前应调用本函数以清除关联的作业，
    /// 否则，未完成的作业可能会触发异常。</remarks>
    function Clear(AObject: Pointer; AMaxTimes: Integer = -1;
      AWaitRunningDone: Boolean = True): Integer; overload;
    /// <summary>清除所有投寄的指定过程作业</summary>
    /// <param name="AProc">要清除的作业执行过程</param>
    /// <param name="AData">要清除的作业附加数据指针地址，如果值为Pointer(-1)，
    /// 则清除所有的相关过程，否则，只清除附加数据地址一致的过程</param>
    /// <param name="AMaxTimes">最多清除的数量，如果<0，则全清</param>
    /// <param name="AWaitRunningDone">是否等待正在运行的作业完成，默认为 true 等待</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer = -1;
      AWaitRunningDone: Boolean = True): Integer; overload;
    /// <summary>清除所有投寄的指定过程作业</summary>
    /// <param name="AProc">要清除的作业执行过程</param>
    /// <param name="AData">要清除的作业附加数据指针地址，如果值为Pointer(-1)，
    /// 则清除所有的相关过程，否则，只清除附加数据地址一致的过程</param>
    /// <param name="AMaxTimes">最多清除的数量，如果<0，则全清</param>
    /// <param name="AWaitRunningDone">是否等待正在运行的作业完成，默认为 true 等待</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(AProc: TQJobProcG; AData: Pointer; AMaxTimes: Integer = -1;
      AWaitRunningDone: Boolean = True): Integer; overload;
{$IFDEF UNICODE}
    /// <summary>清除所有投寄的指定过程作业</summary>
    /// <param name="AProc">要清除的作业执行过程</param>
    /// <param name="AData">要清除的作业附加数据指针地址，如果值为Pointer(-1)，
    /// 则清除所有的相关过程，否则，只清除附加数据地址一致的过程</param>
    /// <param name="AMaxTimes">最多清除的数量，如果<0，则全清</param>
    /// <param name="AWaitRunningDone">是否等待正在运行的作业完成，默认为 true 等待</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(AProc: TQJobProcA; AData: Pointer; AMaxTimes: Integer = -1;
      AWaitRunningDone: Boolean = True): Integer; overload;
{$ENDIF}
    /// <summary>清除指定信号关联的所有作业</summary>
    /// <param name="ASingalName">要清除的信号名称</param>
    /// <param name="AWaitRunningDone">是否等待正在运行的作业完成，默认为 true 等待</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(ASignalName: QStringW; AWaitRunningDone: Boolean = True)
      : Integer; overload;
    /// <summary>清除指定信号关联的所有作业</summary>
    /// <param name="ASingalId">要清除的信号ID</param>
    /// <param name="AWaitRunningDone">是否等待正在运行的作业完成，默认为 true 等待</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(ASignalId: Integer; AWaitRunningDone: Boolean = True)
      : Integer; overload;
    /// <summary>清除指定句柄对应的作业</summary>
    /// <param name="ASingalId">要清除的作业句柄</param>
    /// <param name="AWaitRunningDone">如果作业正在执行中，是否等待完成</param>
    /// <returns>返回实际清除的作业数量</returns>
    procedure ClearSingleJob(AHandle: IntPtr;
      AWaitRunningDone: Boolean = True); overload;

    /// <summary>清除指定的句柄列表中对应的作业</summary>
    /// <param name="AHandles">由Post/At等投递函数返回的句柄列表</param>
    /// <parma name="ACount">AHandles对应的句柄个数</param>
    /// <returns>返回实际清除的作业数量</returns>
    function ClearJobs(AHandles: PIntPtr; ACount: Integer;
      AWaitRunningDone: Boolean = True): Integer; overload;
    /// <summary>触发一个信号</summary>
    /// <param name="AId">信号编码，由RegisterSignal返回</param>
    /// <param name="AData">附加给作业的用户数据指针地址</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <param name="AWaitTimeout">等待所有关联作业执行完成超时时间，单位为毫秒</param>
    /// <returns>如果等待时间不为0，则返回等待结果，如果为0，则返回wrSignaled</returns>
    /// <remarks>触发一个信号后，QWorkers会触发所有已注册的信号关联处理过程的执行</remarks>
    function Signal(AId: Integer; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser; AWaitTimeout: Cardinal = 0)
      : TWaitResult; overload; inline;
    /// <summary>按名称触发一个信号</summary>
    /// <param name="AName">信号名称</param>
    /// <param name="AData">附加给作业的用户数据指针地址</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <param name="AWaitTimeout">等待所有关联作业执行完成超时时间，单位为毫秒</param>
    /// <returns>如果等待时间不为0，则返回等待结果，如果为0，则返回wrSignaled</returns>
    /// <remarks>触发一个信号后，QWorkers会触发所有已注册的信号关联处理过程的执行</remarks>
    function Signal(const AName: QStringW; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser; AWaitTimeout: Cardinal = 0)
      : TWaitResult; overload; inline;
    function SendSignal(AId: Integer; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser; AWaitTimeout: Cardinal = 0)
      : TWaitResult; overload; inline;
    function SendSignal(const AName: QStringW; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser; AWaitTimeout: Cardinal = 0)
      : TWaitResult; overload; inline;
    function PostSignal(AId: Integer; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload; inline;
    function PostSignal(const AName: QStringW; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload; inline;
    /// <summary>注册一个信号</summary>
    /// <param name="AName">信号名称</param>
    /// <remarks>
    /// 1.重复注册同一名称的信号将返回同一个编码
    /// 2.信号一旦注册，则只有程序退出时才会自动释放
    /// </remarks>
    function RegisterSignal(const AName: QStringW): Integer; // 注册一个信号名称
    /// <summary>启用工作者</summary>
    /// <remarks>和DisableWorkers必需配对使用</remarks>
    procedure EnableWorkers;
    /// <summary>禁用所有工作者</summary>
    /// <remarks>禁用所有工作者将使工作者无法获取到新的作业，直到调用EnableWorkers</remarks>
    procedure DisableWorkers;
    /// <summary>枚举所有工作者状态</summary>
    function EnumWorkerStatus: TQWorkerStatus;
    /// <summary>获取指定作业的状态</summary>
    /// <param name="AHandle">作业对象句柄</param>
    /// <param name="AResult">作业对象状态</param>
    /// <returns>如果指定的作业存在，则返回True，否则，返回False</returns>
    /// <remarks>
    /// 1.对于只执行一次的作业，在执行完后不复存在，所以也会返回false
    /// 2.在FMX平台，如果使用了匿名函数作业过程，必需调用 ClearJobState 函数来执行清理过程，以避免内存泄露。
    /// </remarks>
    function PeekJobState(AHandle: IntPtr; var AResult: TQJobState): Boolean;
    /// <summary>枚举所有的作业状态</summary>
    /// <returns>返回作业状态列表</summary>
    /// <remarks>在FMX平台，如果使用了匿名函数作业过程，必需调用 ClearJobStates 函数来执行清理过程</remarks>
    function EnumJobStates: TQJobStateArray;
    /// <summary>等待指定的作业结束</summary>
    /// <param name="AHandle">要等待的作业对象句柄</param>
    /// <param name="ATimeout">超时时间，单位为毫秒</param>
    /// <param name="AMsgWait">等待时是否响应消息</param>
    /// <returns>如果作业不是普通作业，则返回wrError，如果作业不存在或已经结束，返回 wrSignal，否则，返回 wrTimeout</returns>
    function WaitJob(AHandle: IntPtr; ATimeout: Cardinal; AMsgWait: Boolean)
      : TWaitResult;
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProc; AMsgWait: Boolean = false;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static; inline;
{$IFDEF UNICODE}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcA; AMsgWait: Boolean = false;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static; inline;
{$ENDIF}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcG; AMsgWait: Boolean = false;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static; inline;

    /// <summary>最大允许工作者数量，不能小于2</summary>
    property MaxWorkers: Integer read FMaxWorkers write SetMaxWorkers;
    /// <summary>最小工作者数量，不能小于2<summary>
    property MinWorkers: Integer read FMinWorkers write SetMinWorkers;
    /// <summary>最大允许的长时间作业工作者数量，等价于允许开始的长时间作业数量</summary>
    property MaxLongtimeWorkers: Integer read FMaxLongtimeWorkers
      write SetMaxLongtimeWorkers;
    /// <summary>是否允许开始作业，如果为false，则投寄的作业都不会被执行，直到恢复为True</summary>
    /// <remarks>Enabled为False时已经运行的作业将仍然运行，它只影响尚未执行的作来</remarks>
    property Enabled: Boolean read GetEnabled write SetEnabled;
    /// <summary>是否正在释放TQWorkers对象自身</summary>
    property Terminating: Boolean read GetTerminating;
    /// <summary>当前工作者数量</summary>
    property Workers: Integer read FWorkerCount;
    /// <summary>当前忙碌工作者数量</summary>
    property BusyWorkers: Integer read GetBusyCount;
    /// <summary>当前空闲工作者数量</summary>
    property IdleWorkers: Integer read GetIdleWorkers;
    /// <summary>是否已经到达最大工作者数量</summary>
    property OutOfWorker: Boolean read GetOutWorkers;
    /// <summary>默认解雇工作者的超时时间</summary>
    property FireTimeout: Cardinal read FFireTimeout write SetFireTimeout;
    /// <summary>用户指定的作业的Data对象释放方式</summary>
    property OnCustomFreeData: TQCustomFreeDataEvent read FOnCustomFreeData
      write FOnCustomFreeData;
    /// <summary>下一次重复作业触发时间</summary>
    property NextRepeatJobTime: Int64 read GetNextRepeatJobTime;
    /// <summary>在执行作业出错时触发，以便处理异常</summayr>
    property OnError: TWorkerErrorNotify read FOnError write FOnError;
    property BeforeExecute: TQJobNotifyEvent read FBeforeExecute
      write FBeforeExecute;
    property AfterExecute: TQJobNotifyEvent read FAfterExecute
      write FAfterExecute;
    property BeforeCancel: TQJobNotifyEvent read FBeforeCancel
      write FBeforeCancel;
    property SignalQueue: TQSignalQueue read FSignalQueue;
    property WorkerExtClass: TQWorkerExtClass read FWorkerExtClass
      write FWorkerExtClass;
  end;
{$IFDEF UNICODE}

  TQJobItemList = TList<PQJob>;
{$ELSE}
  TQJobItemList = TList;
{$ENDIF}

  TQJobGroup = class
  protected
    FEvent: TEvent; // 事件，用于等待作业完成
    FLocker: TQSimpleLock;
    FItems: TQJobItemList; // 作业列表
    FPrepareCount: Integer; // 准备计数
    FByOrder: Boolean; // 是否按顺序触发作业，即必需等待上一个作业完成后才执行下一个
    FTimeoutCheck: Boolean; // 是否检查作业超时
    FAfterDone: TNotifyEvent; // 作业完成事件通知
    FWaitResult: TWaitResult;
    FRuns: Integer; // 已经运行的数量
    FPosted: Integer; // 已经提交给QWorker执行的数量
    FTag: Pointer;
    FCanceled: Integer;
    FWaitingCount: Integer;
    FRunningWorkers, FMaxWorkers: Integer;
    FFreeAfterDone: Boolean;
    function GetCount: Integer;
    procedure DoJobExecuted(AJob: PQJob);
    procedure DoJobsTimeout(AJob: PQJob);
    procedure DoAfterDone;
    function InitGroupJob(AData: Pointer; AInMainThread: Boolean;
      AFreeType: TQJobDataFreeType): PQJob;
    function InternalAddJob(AJob: PQJob): Boolean;
    function Add(AJob: PQJob): Boolean; overload;
    function InternalInsertJob(AIndex: Integer; AJob: PQJob): Boolean;
  public
    /// <summary>构造函数</summary>
    /// <param name="AByOrder">指定是否是顺序作业，如果为True，则作业会按依次执行</param>
    constructor Create(AByOrder: Boolean = false); overload;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    /// <summary>取消剩下未执行的作业执行</summary>
    /// <param name="AWaitRunningDone">是否等待正在执行的作业执行完成，默认为True</param>
    /// <remark>如果是在分组的子作业中调用Cancel，AWaitRunningDone一定要设置为False，
    /// 否则，如果要等待分组中正在执行的作业完成，则可以设置为True，否则，可以设置为False</remark>
    procedure Cancel(AWaitRunningDone: Boolean = True);
    /// <summary>要准备添加作业，实际增加内部计数器</summary>
    /// <remarks>Prepare和Run必需匹配使用，否则可能造成作业不会被执行</remarks>
    procedure Prepare;
    /// <summary>减少内部计数器，如果计数器减为0，则开始实际执行作业</summary>
    /// <param name="ATimeout">等待时长，单位为毫秒</param>
    procedure Run(ATimeout: Cardinal = INFINITE);
    /// <summary>插入一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AIndex">要插入的的位置索引</param>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Insert(AIndex: Integer; AProc: TQJobProc; AData: Pointer;
      AInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    /// <summary>插入一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AIndex">要插入的的位置索引</param>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Insert(AIndex: Integer; AProc: TQJobProcG; AData: Pointer;
      AInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$IFDEF UNICODE}
    /// <summary>插入一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AIndex">要插入的的位置索引</param>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Insert(AIndex: Integer; AProc: TQJobProcA; AData: Pointer;
      AInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$ENDIF}
    /// <summary>添加一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Add(AProc: TQJobProc; AData: Pointer;
      AInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    /// <summary>添加一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Add(AProc: TQJobProcG; AData: Pointer;
      AInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$IFDEF UNICODE}
    /// <summary>添加一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Add(AProc: TQJobProcA; AData: Pointer;
      AInMainThread: Boolean = false;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$ENDIF}
    /// <summary>等待作业完成</summary>
    /// <param name="ATimeout">最长等待时间，单位为毫秒</param>
    /// <returns>返回等待结果</returns>
    /// <remarks>WaitFor会阻塞当前线程的执行，如果是主线程中调用，建议使用MsgWaitFor
    /// 以保证在主线中的作业能够被执行</remarks>
    function WaitFor(ATimeout: Cardinal = INFINITE): TWaitResult; overload;
    /// <summary>等待作业完成</summary>
    /// <param name="ATimeout">最长等待时间，单位为毫秒</param>
    /// <returns>返回等待结果</returns>
    /// <remarks>如果当前在主线程中执行,MsgWaitFor会检查是否有消息需要处理，而
    /// WaitFor不会，如果在后台线程中执行，会直接调用WaitFor。因此，在主线程中调用
    /// WaitFor会影响主线程中作业的执行，而MsgWaitFor不会
    /// </remarks>
    function MsgWaitFor(ATimeout: Cardinal = INFINITE): TWaitResult;
    /// <summary>未完成的作业数量</summary>
    property Count: Integer read GetCount;
    /// <summary>全部作业执行完成时触发的回调事件</summary>
    property AfterDone: TNotifyEvent read FAfterDone write FAfterDone;
    /// <summary>是否是按顺序执行，只能在构造函数中指定，此处只读</summary>
    property ByOrder: Boolean read FByOrder;
    /// <summary>用户自定的分组附加标签</summary>
    property Tag: Pointer read FTag write FTag;
    /// <summary>是否在作业完成后自动释放自身</summary>
    property FreeAfterDone: Boolean read FFreeAfterDone write FFreeAfterDone;
    /// <summary>已执行完成的作业数量</summary>
    property Runs: Integer read FRuns;
    /// <summary>允许同时执行的工作者数量，<=0为不限制（默认）>/summary>
    property MaxWorkers: Integer read FMaxWorkers write FMaxWorkers;
  end;

  TQForJobs = class
  private
    FStartIndex, FStopIndex, FIterator: TForLoopIndexType;
    FBreaked: Integer;
    FEvent: TEvent;
    FWorkerCount: Integer;
    FWorkJob: PQJob;
    procedure DoJob(AJob: PQJob);
    procedure Start;
    function Wait(AMsgWait: Boolean): TWaitResult;
    function GetBreaked: Boolean;
    function GetRuns: Cardinal; inline;
    function GetTotalTime: Cardinal; inline;
    function GetAvgTime: Cardinal; inline;
  public
    constructor Create(const AStartIndex, AStopIndex: TForLoopIndexType;
      AData: Pointer; AFreeType: TQJobDataFreeType = jdfFreeByUser); overload;
    destructor Destroy; override;
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProc; AMsgWait: Boolean = false;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static;
{$IFDEF UNICODE}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcA; AMsgWait: Boolean = false;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static;
{$ENDIF}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcG; AMsgWait: Boolean = false;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static;
    procedure Run(AWorkerProc: TQForJobProc;
      AMsgWait: Boolean = false); overload;
    procedure Run(AWorkerProc: TQForJobProcG;
      AMsgWait: Boolean = false); overload;
{$IFDEF UNICODE}
    procedure Run(AWorkerProc: TQForJobProcA;
      AMsgWait: Boolean = false); overload;
{$ENDIF}
    /// <summary>中断循环的执行</summary>
    procedure BreakIt;
    /// <summary>起始索引</summary>
    property StartIndex: TForLoopIndexType read FStartIndex;
    /// <summary>结束索引</summary>
    property StopIndex: TForLoopIndexType read FStopIndex;
    /// <summary>已中断</summary>
    property Breaked: Boolean read GetBreaked;
    /// <summary>已运行次数<summary>
    property Runs: Cardinal read GetRuns;
    /// <summary>总运行时间，精度为0.1ms</summary>
    property TotalTime: Cardinal read GetTotalTime;
    /// <summary>平均每次调用用时，精度为0.1ms</summary>
    property AvgTime: Cardinal read GetAvgTime;
  end;

type
  TGetThreadStackInfoFunction = function(AThread: TThread): QStringW;
  TMainThreadProc = procedure(AData: Pointer) of object;
  TMainThreadProcG = procedure(AData: Pointer);
  /// <summary>将全局的作业处理函数转换为TQJobProc类型，以便正常调度使用</summary>
  /// <param name="AProc">全局的作业处理函数</param>
  /// <returns>返回新的TQJobProc实例</returns>
function MakeJobProc(const AProc: TQJobProcG): TMethod; overload;
{$IFDEF UNICODE}
function MakeJobProc(const AProc: TQJobProcA): TMethod; overload;
{$ENDIF}
// 获取系统中CPU的核心数量
function GetCPUCount: Integer;
// 获取当前系统的时间戳，最高可精确到0.1ms，但实际受操作系统限制
function GetTimestamp: Int64;
// 设置线程运行的CPU
procedure SetThreadCPU(AHandle: THandle; ACpuNo: Integer);
// 原子锁定与运算
function AtomicAnd(var Dest: Integer; const AMask: Integer): Integer;
// 原子锁定或运算
function AtomicOr(var Dest: Integer; const AMask: Integer): Integer;
/// <summary>获取作业对象池中缓存的作业对象数量</summary>
function JobPoolCount: NativeInt;
/// <summary>打印作业池中缓存的作业对象信息</summary>
function JobPoolPrint: QStringW;
/// <summary>清除指定作业状态的状态信息</summary>
/// <param name="AState">作业状态</param>
procedure ClearJobState(var AState: TQJobState); inline;
/// <summary>清除指定作业状态数组的状态信息</summary>
/// <param name="AStates">作业状态数组</param>
procedure ClearJobStates(var AStates: TQJobStateArray);
/// <summary>在主线程中执行指定的函数</summary>
/// <param name="AProc">要执行的函数</param>
/// <param name="AData">附加参数</param>
procedure RunInMainThread(AProc: TMainThreadProc; AData: Pointer); overload;
/// <summary>在主线程中执行指定的函数</summary>
/// <param name="AProc">要执行的函数</param>
/// <param name="AData">附加参数</param>
procedure RunInMainThread(AProc: TMainThreadProcG; AData: Pointer); overload;
{$IFDEF UNICODE}
/// <summary>在主线程中执行指定的函数</summary>
/// <param name="AProc">要执行的函数</param>
procedure RunInMainThread(AProc: TThreadProcedure); overload;
{$ENDIF}
/// <summary>判断指定线程ID对应的函数是否存在</summary>
/// <param name="AThreadId">线程ID</param>
/// <param name="AProcessId">进程ID，如果为$FFFFFFFF，则不检查，如果为0，则为当前进程</param>
/// <returns>如果存在，则返回True，否则返回False</returns>
function ThreadExists(AThreadId: TThreadId; AProcessId: DWORD = 0): Boolean;
/// <summary>不阻塞消息循环来等待某一事件发生</summary>
/// <param name="AEvent">要等待发生的事件</param>
/// <param name="ATimeout">等待超时时间，单位毫秒</param>
/// <returns>返回等待结果</returns>
function MsgWaitForEvent(AEvent: TEvent; ATimeout: Cardinal): TWaitResult;

var
  Workers: TQWorkers;
  GetThreadStackInfo: TGetThreadStackInfoFunction;

implementation

{$IFDEF USE_MAP_SYMBOLS}

uses qmapsymbols;
{$ENDIF}

resourcestring
  SNotSupportNow = '当前尚未支持功能 %s';
  STooFewWorkers = '指定的最小工作者数量太少(必需大于等于1)。';
  SMaxMinWorkersError = '指定的最小工作者数量大于最大工作者数量。';
  STooManyLongtimeWorker = '不能允许太多长时间作业线程(最多允许工作者一半)。';
  SBadWaitDoneParam = '未知的等待正在执行作业完成方式:%d';
  SUnsupportPlatform = '%s 当前在本平台不受支持。';
  STerminateMainThreadJobInMainThread =
    '在主线程中等待主线程作业结束可能会造成死循环，请将 AWaitRunningDone 参数设置为 false。';

type
{$IFDEF MSWINDOWS}
  TGetTickCount64 = function: Int64;
  TGetSystemTimes = function(var lpIdleTime, lpKernelTime,
    lpUserTime: TFileTime): BOOL; stdcall;
  TOpenThread = function(dwDesiredAccess: DWORD; bInheritHandle: Boolean;
    dwThreadId: DWORD): THandle; stdcall;
{$ENDIF MSWINDOWS}

  TJobPool = class
  protected
    FFirst: PQJob;
    FCount: Integer;
    FSize: Integer;
    FLocker: TQSimpleLock;
  public
    constructor Create(AMaxSize: Integer); overload;
    destructor Destroy; override;
    procedure Push(AJob: PQJob);
    function Pop: PQJob;
    property Count: Integer read FCount;
    property Size: Integer read FSize write FSize;
  end;
{$IF RTLVersion<24}

  TSystemTimes = record
    IdleTime, UserTime, KernelTime, NiceTime: UInt64;
  end;
{$IFEND <XE3}

  TStaticThread = class(TThread)
  protected
    FEvent: TEvent;
    FLastTimes:
{$IF RTLVersion>=24}TThread.{$IFEND >=XE5}TSystemTimes;
    procedure Execute; override;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure CheckNeeded;
  end;

  TRunInMainThreadHelper = class
    FProc: TMainThreadProc;
    FData: Pointer;
    procedure Execute;
  end;

var
  JobPool: TJobPool;
  _CPUCount: Integer;
  AppTerminated: Boolean;
{$IFDEF MSWINDOWS}
  GetTickCount64: TGetTickCount64;
  WinGetSystemTimes: TGetSystemTimes;
  OpenThread: TOpenThread;
  _PerfFreq: Int64;
  _StartCounter: Int64;
{$ELSE}
  _Watch: TStopWatch;
{$ENDIF}
{$IFDEF __BORLANDC}
procedure FreeAsCDelete(AData: Pointer); external;
procedure FreeAsCDeleteArray(AData: Pointer); external;
{$ENDIF}

procedure ThreadYield;
begin
{$IFDEF MSWINDOWS}
  SwitchToThread;
{$ELSE}
  TThread.Yield;
{$ENDIF}
end;

function ThreadExists(AThreadId: TThreadId; AProcessId: DWORD): Boolean;
{$IFDEF MSWINDOWS}
  function WinThreadExists: Boolean;
  var
    AHandle: THandle;
    AExitCode: DWORD;
  const
    THREAD_QUERY_INFORMATION = $0040;
    THREAD_SUSPEND_RESUME = $0002;
  begin
    AHandle := OpenThread(THREAD_SUSPEND_RESUME, True, AThreadId);
    Result := AHandle <> 0;
    if Result then
    begin
      Result := SuspendThread(AHandle) <> Cardinal(-1); // 线程如果已经中止,则不能控制它暂停
      if Result then // 如果存在,则恢复执行(具体则取决于计数)
        ResumeThread(AHandle);
      CloseHandle(AHandle);
    end;
  end;
{$ENDIF}
{$IFDEF POSIX}
  function PosixThreadExists: Boolean;
  var
    P: Integer;
    J: sched_param;
  begin
    Result := pthread_getschedparam(pthread_t(AThreadId), P, J) <> ESRCH;
  end;
{$ENDIF}

begin
{$IFDEF POSIX}
  Result := PosixThreadExists;
{$ELSE}
  Result := WinThreadExists;
{$ENDIF}
end;

function ProcessAppMessage: Boolean;
{$IFDEF MSWINDOWS}
var
  AMsg: MSG;
{$ENDIF}
begin
{$IFNDEF CONSOLE}
{$IFDEF MSWINDOWS}
  Result := True;
  while PeekMessage(AMsg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(AMsg);
    DispatchMessage(AMsg);
    if AMsg.message = WM_QUIT then
      AppTerminated := True;
  end;
  if AppTerminated then
    PostQuitMessage(ExitCode);
{$ELSE}
  Application.ProcessMessages;
  AppTerminated := Application.Terminated;
{$ENDIF}
{$ENDIF}
  Result := not AppTerminated;
end;

function MsgWaitForEvent(AEvent: TEvent; ATimeout: Cardinal): TWaitResult;
var
  T: Cardinal;
{$IFDEF MSWINDOWS}
  AHandles: array [0 .. 0] of THandle;
  rc: DWORD;
{$ENDIF}
begin
  if GetCurrentThreadId <> MainThreadId then
    Result := AEvent.WaitFor(ATimeout)
  else
  begin
{$IFDEF MSWINDOWS}
    Result := wrTimeout;
    AHandles[0] := AEvent.Handle;
    repeat
      T := GetTickCount;
      rc := MsgWaitForMultipleObjects(1, AHandles[0], false, ATimeout,
        QS_ALLINPUT);
      if rc = WAIT_OBJECT_0 + 1 then
      begin
        if ProcessAppMessage then
        begin
          T := GetTickCount - T;
          if ATimeout > T then
            Dec(ATimeout, T)
          else
          begin
            Result := wrTimeout;
            Break;
          end;
        end
        else
        begin
          Result := wrAbandoned;
          Break;
        end;
      end
      else
      begin
        case rc of
          WAIT_ABANDONED:
            Result := wrAbandoned;
          WAIT_OBJECT_0:
            Result := wrSignaled;
          WAIT_TIMEOUT:
            Result := wrTimeout;
          WAIT_FAILED:
            Result := wrError;
          WAIT_IO_COMPLETION:
            Result := wrIOCompletion;
        end;
        Break;
      end;
    until false;
{$ELSE}
    repeat
      // 每隔10毫秒检查一下是否有消息需要处理，有则处理，无则进入下一个等待
      T := GetTimestamp;
      if ProcessAppMessage then
      begin
        Result := AEvent.WaitFor(10);
        if Result = wrTimeout then
        begin
          T := (GetTimestamp - T) div 10;
          if ATimeout > T then
            Dec(ATimeout, T)
          else
            Break;
        end
        else
          Break;
      end
      else
      begin
        Result := wrAbandoned;
        Break;
      end;
    until false;
{$ENDIF}
  end;
end;

procedure ClearJobState(var AState: TQJobState);
begin
{$IFDEF UNICODE}
  if (AState.Proc.Data = Pointer(-1)) then
    TQJobProcA(AState.Proc.ProcA) := nil;
{$ENDIF}
  if IsFMXApp then
  begin
    AState.Proc.Code := nil;
    AState.Proc.Data := nil;
  end;
end;

function IsObjectJob(AJob: PQJob; AData: Pointer): Boolean;
begin
  Result := (AJob.WorkerProc.Data = AData) or
    (AJob.IsGrouped and (AJob.Group = AData));
end;

procedure ClearJobStates(var AStates: TQJobStateArray);
var
  I: Integer;
begin
  for I := 0 to High(AStates) do
    ClearJobState(AStates[I]);
  SetLength(AStates, 0);
end;

procedure JobInitialize(AJob: PQJob; AData: Pointer;
  AFreeType: TQJobDataFreeType; ARunOnce, ARunInMainThread: Boolean); inline;
begin
  AJob.Data := AData;
  if AData <> nil then
  begin
    AJob.Flags := AJob.Flags or (Integer(AFreeType) shl 8);
    if AFreeType = jdfFreeAsInterface then
      IUnknown(AData)._AddRef
{$IFDEF AUTOREFCOUNT}
      // 移动平台下AData的计数需要增加，以避免自动释放
    else if AFreeType = jdfFreeAsObject then
      TObject(AData).__ObjAddRef;
{$ENDIF}
    ;
  end;
  AJob.SetFlags(JOB_RUN_ONCE, ARunOnce);
  AJob.SetFlags(JOB_IN_MAINTHREAD, ARunInMainThread);
end;

// 位与，返回原值
function AtomicAnd(var Dest: Integer; const AMask: Integer): Integer; inline;
var
  I: Integer;
begin
  repeat
    Result := Dest;
    I := Result and AMask;
  until AtomicCmpExchange(Dest, I, Result) = Result;
end;

// 位或，返回原值
function AtomicOr(var Dest: Integer; const AMask: Integer): Integer; inline;
var
  I: Integer;
begin
  repeat
    Result := Dest;
    I := Result or AMask;
  until AtomicCmpExchange(Dest, I, Result) = Result;
end;

procedure SetThreadCPU(AHandle: THandle; ACpuNo: Integer);
begin
{$IFDEF MSWINDOWS}
  SetThreadIdealProcessor(AHandle, ACpuNo);
{$ELSE}
  // Linux/Andriod/iOS暂时忽略,XE6未引入sched_setaffinity定义,啥时引入了再加以支持
{$ENDIF}
end;

// 返回值的时间精度为100ns，即0.1ms
function GetTimestamp: Int64;
begin
{$IFDEF MSWINDOWS}
  if _PerfFreq > 0 then
  begin
    QueryPerformanceCounter(Result);
    Result := Trunc((Result - _StartCounter) / _PerfFreq * 10000);
  end
  else if Assigned(GetTickCount64) then
    Result := (GetTickCount64 - _StartCounter) * 10
  else
    Result := (GetTickCount - _StartCounter) * 10;
{$ELSE}
  Result := _Watch.Elapsed.Ticks div 1000;
{$ENDIF}
end;

function GetCPUCount: Integer;
{$IFDEF MSWINDOWS}
var
  si: SYSTEM_INFO;
{$ENDIF}
begin
  if _CPUCount = 0 then
  begin
{$IFDEF MSWINDOWS}
    GetSystemInfo(si);
    Result := si.dwNumberOfProcessors;
{$ELSE}// Linux,MacOS,iOS,Andriod{POSIX}
{$IFDEF POSIX}
{$WARN SYMBOL_PLATFORM OFF}
    Result := sysconf(_SC_NPROCESSORS_ONLN);
{$WARN SYMBOL_PLATFORM ON}
{$ELSE}// 不认识的操作系统，CPU数默认为1
    Result := 1;
{$ENDIF !POSIX}
{$ENDIF !MSWINDOWS}
  end
  else
    Result := _CPUCount;
end;

function MakeJobProc(const AProc: TQJobProcG): TMethod;
begin
  Result.Data := nil;
  Result.Code := @AProc;
end;
{$IFDEF UNICODE}

function MakeJobProc(const AProc: TQJobProcA): TMethod;
var
  AMethod: TMethod absolute Result;
begin
  AMethod.Data := Pointer(-1);
  AMethod.Code := nil;
  TQJobProcA(AMethod.Code) := AProc;
end;
{$ENDIF}

function SameWorkerProc(const P1: TQJobMethod; P2: TQJobProc): Boolean; inline;
begin
  Result := (P1.Code = TMethod(P2).Code) and (P1.Data = TMethod(P2).Data);
end;
{ TQJob }

procedure TQJob.AfterRun(AUsedTime: Int64);
begin
  Inc(Runs);
  if AUsedTime > 0 then
  begin
    Inc(TotalUsedTime, AUsedTime);
    if MinUsedTime = 0 then
      MinUsedTime := AUsedTime
    else if MinUsedTime > AUsedTime then
      MinUsedTime := AUsedTime;
    if MaxUsedTime = 0 then
      MaxUsedTime := AUsedTime
    else if MaxUsedTime < AUsedTime then
      MaxUsedTime := AUsedTime;
  end;
end;

procedure TQJob.Assign(const ASource: PQJob);
begin
  Self := ASource^;
{$IFDEF UNICODE}
  if IsAnonWorkerProc then
  begin
    WorkerProc.ProcA := nil;
    TQJobProcA(WorkerProc.ProcA) := TQJobProcA(ASource.WorkerProc.ProcA);
  end;
{$ENDIF}
  // 下面成员不拷贝
  Worker := nil;
  Next := nil;
end;

constructor TQJob.Create(AProc: TQJobProc);
begin
{$IFDEF NEXTGEN}
  PQJobProc(@WorkerProc)^ := AProc;
{$ELSE}
  WorkerProc.Proc := AProc;
{$ENDIF}
  SetFlags(JOB_RUN_ONCE, True);
end;

function TQJob.GetAvgTime: Integer;
begin
  if Runs > 0 then
    Result := TotalUsedTime div Cardinal(Runs)
  else
    Result := 0;
end;

function TQJob.GetIsAnonWorkerProc: Boolean;
begin
  Result := (WorkerProc.Data = Pointer(-1));
end;

function TQJob.GetIsCustomFree: Boolean;
begin
  Result := FreeType in [jdfFreeAsC1 .. jdfFreeAsC6];
end;

function TQJob.GetIsInterfaceOwner: Boolean;
begin
  Result := (FreeType = jdfFreeAsInterface);
end;

function TQJob.GetIsObjectOwner: Boolean;
begin
  Result := (FreeType = jdfFreeAsObject);
end;

function TQJob.GetIsPlanRunning: Boolean;
begin
  if IsByPlan then
    Result := ExtData.AsPlan.Runnings > 0
  else
    Result := false;
end;

function TQJob.GetIsRecordOwner: Boolean;
begin
  Result := (FreeType = jdfFreeAsSimpleRecord);
end;

function TQJob.GetIsTerminated: Boolean;
begin
  if Assigned(Worker) then
    Result := Workers.Terminating or Worker.Terminated or
      ((Flags and JOB_TERMINATED) <> 0) or (Worker.FTerminatingJob = @Self)
  else
    Result := (Flags and JOB_TERMINATED) <> 0;
end;

function TQJob.GetElapsedTime: Int64;
begin
  Result := GetTimestamp - StartTime;
end;

function TQJob.GetExtData: TQJobExtData;
begin
  Result := Data;
end;

function TQJob.GetFlags(AIndex: Integer): Boolean;
begin
  Result := (Flags and AIndex) <> 0;
end;

function TQJob.GetFreeType: TQJobDataFreeType;
begin
  Result := TQJobDataFreeType((Flags shr 8) and $0F);
end;

function TQJob.GetHandle: IntPtr;
var
  AMask: IntPtr;
begin
  if IsSignalWakeup then
  begin
    AMask := JOB_HANDLE_SIGNAL_MASK;
    if Assigned(Source) then
      Result := IntPtr(Source) or AMask
    else
      Result := IntPtr(@Self) or AMask;
  end
  else
  begin
    if IsByPlan then
      AMask := JOB_HANDLE_PLAN_MASK
    else if (FirstDelay <> 0) or (not Runonce) then
      AMask := JOB_HANDLE_REPEAT_MASK
    else
      AMask := JOB_HANDLE_SIMPLE_MASK;
    Result := IntPtr(@Self) or AMask;
  end;
end;

procedure TQJob.Reset;
begin

  FillChar(Self, SizeOf(TQJob), 0);
end;

procedure TQJob.SetFlags(AIndex: Integer; AValue: Boolean);
begin
  if AValue then
    Flags := (Flags or AIndex)
  else
    Flags := (Flags and (not AIndex));
end;

procedure TQJob.SetFreeType(const Value: TQJobDataFreeType);
begin
  Flags := (Flags and (not JOB_DATA_OWNER)) or (Integer(Value) shl 8);
end;

procedure TQJob.SetIsTerminated(const Value: Boolean);
begin
  SetFlags(JOB_TERMINATED, Value);
end;
{$IFDEF UNICODE}

procedure TQJob.Synchronize(AProc: TThreadProcedure);
begin
  if GetCurrentThreadId = MainThreadId then
    AProc
  else
    Worker.Synchronize(AProc);
end;
{$ENDIF}

procedure TQJob.Synchronize(AMethod: TThreadMethod);
begin
  if GetCurrentThreadId = MainThreadId then
    AMethod
  else
    Worker.Synchronize(AMethod);
end;

procedure TQJob.UpdateNextTime;
begin
  if IsDelayRepeat then
    NextTime := GetTimestamp + FirstDelay
  else if (Runs = 0) and (FirstDelay <> 0) then
    NextTime := PushTime + FirstDelay
  else if Interval <> 0 then
  begin
    if NextTime = 0 then
      NextTime := GetTimestamp + Interval
    else
      Inc(NextTime, Interval);
  end
  else
    NextTime := GetTimestamp;
end;

{ TQSimpleJobs }

function TQSimpleJobs.Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
var
  AFirst, AJob, APrior, ANext: PQJob;
begin
  // 先将SimpleJobs所有的异步作业清空，以防止被弹出执行
  AJob := PopAll;
  Result := 0;
  APrior := nil;
  AFirst := nil;
  while (AJob <> nil) and (AMaxTimes <> 0) do
  begin
    ANext := AJob.Next;
    if IsObjectJob(AJob, AObject) and (not AJob.IsPlanRunning) then
    begin
      if APrior <> nil then
        APrior.Next := ANext
      else // 首个
        AFirst := ANext;
      AJob.Next := nil;
      FOwner.FreeJob(AJob);
      Dec(AMaxTimes);
      Inc(Result);
    end
    else
    begin
      if AFirst = nil then
        AFirst := AJob;
      APrior := AJob;
    end;
    AJob := ANext;
  end;
  Repush(AFirst);
end;

function TQSimpleJobs.Clear(AProc: TQJobProc; AData: Pointer;
  AMaxTimes: Integer): Integer;
var
  AFirst, AJob, APrior, ANext: PQJob;
begin
  AJob := PopAll;
  Result := 0;
  APrior := nil;
  AFirst := nil;
  while (AJob <> nil) and (AMaxTimes <> 0) do
  begin
    ANext := AJob.Next;
    if SameWorkerProc(AJob.WorkerProc, AProc) and (not AJob.IsPlanRunning) and
      ((AJob.Data = AData) or (AData = INVALID_JOB_DATA)) then
    begin
      if APrior <> nil then
        APrior.Next := ANext
      else // 首个
        AFirst := ANext;
      AJob.Next := nil;
      FOwner.FreeJob(AJob);
      Dec(AMaxTimes);
      Inc(Result);
    end
    else
    begin
      if AFirst = nil then
        AFirst := AJob;
      APrior := AJob;
    end;
    AJob := ANext;
  end;
  Repush(AFirst);
end;

procedure TQSimpleJobs.Clear;
var
  AFirst: PQJob;
begin
  FLocker.Enter;
  AFirst := FFirst;
  FFirst := nil;
  FLast := nil;
  FCount := 0;
  FLocker.Leave;
  FOwner.FreeJob(AFirst);
end;

function TQSimpleJobs.Clear(AHandle: IntPtr): Boolean;
var
  AFirst, AJob, APrior, ANext: PQJob;
begin
  AJob := PopAll;
  Result := false;
  APrior := nil;
  AFirst := nil;
  while AJob <> nil do
  begin
    ANext := AJob.Next;
    if (IntPtr(AJob) = AHandle) and (not AJob.IsPlanRunning) then
    begin
      if APrior <> nil then
        APrior.Next := ANext
      else // 首个
        AFirst := ANext;
      AJob.Next := nil;
      FOwner.FreeJob(AJob);
      Result := True;
      Break;
    end
    else
    begin
      if AFirst = nil then
        AFirst := AJob;
      APrior := AJob;
    end;
    AJob := ANext;
  end;
  Repush(AFirst);
end;

constructor TQSimpleJobs.Create(AOwner: TQWorkers);
begin
  inherited Create(AOwner);
  FLocker := TQSimpleLock.Create;
end;

destructor TQSimpleJobs.Destroy;
begin
  inherited;
  FreeObject(FLocker);
end;

function TQSimpleJobs.GetCount: Integer;
begin
  Result := FCount;
end;

function TQSimpleJobs.InternalPop: PQJob;
begin
  FLocker.Enter;
  Result := FFirst;
  if Result <> nil then
  begin
    FFirst := Result.Next;
    if FFirst = nil then
      FLast := nil;
    Dec(FCount);
  end;
  FLocker.Leave;
end;

function TQSimpleJobs.InternalPush(AJob: PQJob): Boolean;
begin
  FLocker.Enter;
  if FLast = nil then
    FFirst := AJob
  else
    FLast.Next := AJob;
  FLast := AJob;
  Inc(FCount);
  FLocker.Leave;
  Result := True;
end;

function TQSimpleJobs.PopAll: PQJob;
begin
  FLocker.Enter;
  Result := FFirst;
  FFirst := nil;
  FLast := nil;
  FCount := 0;
  FLocker.Leave;
end;

procedure TQSimpleJobs.Repush(ANewFirst: PQJob);
var
  ALast: PQJob;
  ACount: Integer;
begin
  if ANewFirst <> nil then
  begin
    ALast := ANewFirst;
    ACount := 0;
    while ALast.Next <> nil do
    begin
      ALast := ALast.Next;
      Inc(ACount);
    end;
    FLocker.Enter;
    ALast.Next := FFirst;
    FFirst := ANewFirst;
    if FLast = nil then
      FLast := ALast;
    Inc(FCount, ACount);
    FLocker.Leave;
  end;
end;

function TQSimpleJobs.ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
var
  AFirst, AJob, APrior, ANext: PQJob;
  // AHandleEof: PIntPtr;
  function Accept(AJob: PQJob): Boolean;
  var
    P: PIntPtr;
  begin
    P := AHandles;
    Result := false;
    while IntPtr(P) < IntPtr(AHandles) do
    begin
      if (IntPtr(P^) and (not $03)) = IntPtr(AJob) then
      begin
        P^ := 0; // 置空
        Result := True;
        Exit;
      end;
      Inc(P);
    end;
  end;

begin
  AJob := PopAll;
  Result := 0;
  APrior := nil;
  AFirst := nil;
  // AHandleEof := AHandles;
  // Inc(AHandleEof, ACount);
  while AJob <> nil do
  begin
    ANext := AJob.Next;
    if Accept(AJob) then
    begin
      if APrior <> nil then
        APrior.Next := ANext;
      AJob.Next := nil;
      FOwner.FreeJob(AJob);
      Inc(Result);
      Break;
    end
    else
    begin
      if AFirst = nil then
        AFirst := AJob;
      APrior := AJob;
    end;
    AJob := ANext;
  end;
  Repush(AFirst);
end;

{ TQJobs }

procedure TQJobs.Clear;
var
  AItem: PQJob;
begin
  repeat
    AItem := Pop;
    if AItem <> nil then
      FOwner.FreeJob(AItem)
    else
      Break;
  until 1 > 2;
end;

function TQJobs.Clear(AHandle: IntPtr): Boolean;
begin
  Result := ClearJobs(@AHandle, 1) = 1;
end;

constructor TQJobs.Create(AOwner: TQWorkers);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TQJobs.Destroy;
begin
  Clear;
  inherited;
end;

function TQJobs.GetEmpty: Boolean;
begin
  Result := (Count = 0);
end;

function TQJobs.Pop: PQJob;
begin
  Result := InternalPop;
  if Result <> nil then
  begin
    Result.PopTime := GetTimestamp;
    Result.Next := nil;
  end;
end;

function TQJobs.Push(AJob: PQJob): Boolean;
begin
  // Assert(AJob.WorkerProc.Code<>nil);
  AJob.Owner := Self;
  AJob.PushTime := GetTimestamp;
  Result := InternalPush(AJob);
  if not Result then
  begin
    AJob.Next := nil;
    FOwner.FreeJob(AJob);
  end;
end;

{ TQRepeatJobs }

procedure TQRepeatJobs.Clear;
begin
  FLocker.Enter;
  try
    FItems.Clear;
    FFirstFireTime := 0;
  finally
    FLocker.Leave;
  end;
end;

function TQRepeatJobs.Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
var
  ANode, ANext: TQRBNode;
  APriorJob, AJob, ANextJob: PQJob;
  ACanDelete: Boolean;
begin
  // 现在清空重复的计划作业
  Result := 0;
  FLocker.Enter;
  try
    ANode := FItems.First;
    while (ANode <> nil) and (AMaxTimes <> 0) do
    begin
      ANext := ANode.Next;
      AJob := ANode.Data;
      ACanDelete := True;
      APriorJob := nil;
      while AJob <> nil do
      begin
        ANextJob := AJob.Next;
        if IsObjectJob(AJob, AObject) then
        begin
          if ANode.Data = AJob then
            ANode.Data := AJob.Next;
          if Assigned(APriorJob) then
            APriorJob.Next := AJob.Next;
          AJob.Next := nil;
          FOwner.FreeJob(AJob);
          Dec(AMaxTimes);
          Inc(Result);
        end
        else
        begin
          ACanDelete := false;
          APriorJob := AJob;
        end;
        AJob := ANextJob;
      end;
      if ACanDelete then
        FItems.Delete(ANode);
      ANode := ANext;
    end;
    if FItems.Count > 0 then
      FFirstFireTime := PQJob(FItems.First.Data).NextTime
    else
      FFirstFireTime := 0;
  finally
    FLocker.Leave;
  end;
end;

procedure TQRepeatJobs.AfterJobRun(AJob: PQJob; AUsedTime: Int64);
var
  ANode: TQRBNode;
  AWorkerLookupNeeded: Boolean;
  function UpdateSource: Boolean;
  var
    ATemp, APrior: PQJob;
  begin
    Result := false;
    ATemp := ANode.Data;
    APrior := nil;
    while ATemp <> nil do
    begin
      if ATemp = AJob.Source then
      begin
        if AJob.IsTerminated then
        begin
          if APrior <> nil then
            APrior.Next := ATemp.Next
          else
            ANode.Data := ATemp.Next;
          ATemp.Next := nil;
          FOwner.FreeJob(ATemp);
          if ANode.Data = nil then
            FItems.Delete(ANode);
        end
        else
        begin
          ATemp.AfterRun(AUsedTime);
          if ATemp.IsDelayRepeat then
          begin
            if APrior <> nil then
              APrior.Next := ATemp.Next
            else
              ANode.Data := ATemp.Next;
            if ANode.Data = nil then
              FItems.Delete(ANode);
            ATemp.Next := nil;
            InternalPush(ATemp);
            AWorkerLookupNeeded := True;
          end;
        end;
        Result := True;
        Break;
      end;
      APrior := ATemp;
      ATemp := ATemp.Next;
    end;
  end;

begin
  AWorkerLookupNeeded := false;
  FLocker.Enter;
  try
    ANode := FItems.Find(AJob);
    if ANode <> nil then
    begin
      if UpdateSource then
        Exit;
    end;
    ANode := FItems.First;
    while ANode <> nil do
    begin
      if UpdateSource then
        Break;
      ANode := ANode.Next;
    end;
  finally
    FLocker.Leave;
    if AWorkerLookupNeeded then
      FOwner.LookupIdleWorker(false);
  end;
end;

function TQRepeatJobs.Clear(AProc: TQJobProc; AData: Pointer;
  AMaxTimes: Integer): Integer;
var
  AJob, APrior, ANext: PQJob;
  ANode, ANextNode: TQRBNode;
begin
  Result := 0;
  FLocker.Enter;
  try
    ANode := FItems.First;
    while (ANode <> nil) and (AMaxTimes <> 0) do
    begin
      AJob := ANode.Data;
      APrior := nil;
      repeat
        if SameWorkerProc(AJob.WorkerProc, AProc) and
          ((AData = INVALID_JOB_DATA) or (AData = AJob.Data)) then
        begin
          ANext := AJob.Next;
          if APrior = nil then
            ANode.Data := ANext
          else
            APrior.Next := AJob.Next;
          AJob.Next := nil;
          FOwner.FreeJob(AJob);
          AJob := ANext;
          Dec(AMaxTimes);
          Inc(Result);
        end
        else
        begin
          APrior := AJob;
          AJob := AJob.Next
        end;
      until AJob = nil;
      if ANode.Data = nil then
      begin
        ANextNode := ANode.Next;
        FItems.Delete(ANode);
        ANode := ANextNode;
      end
      else
        ANode := ANode.Next;
    end;
    if FItems.Count > 0 then
      FFirstFireTime := PQJob(FItems.First.Data).NextTime
    else
      FFirstFireTime := 0;
  finally
    FLocker.Leave;
  end;
end;

constructor TQRepeatJobs.Create(AOwner: TQWorkers);
begin
  inherited;
  FItems := TQRBTree.Create(DoTimeCompare);
  FItems.OnDelete := DoJobDelete;
  FLocker := TCriticalSection.Create;
end;

destructor TQRepeatJobs.Destroy;
begin
  inherited;
  FreeObject(FItems);
  FreeObject(FLocker);
end;

procedure TQRepeatJobs.DoJobDelete(ATree: TQRBTree; ANode: TQRBNode);
begin
  FOwner.FreeJob(ANode.Data);
end;

function TQRepeatJobs.DoTimeCompare(P1, P2: Pointer): Integer;
var
  ATemp: Int64;
begin
  ATemp := PQJob(P1).NextTime - PQJob(P2).NextTime;
  if ATemp < 0 then
    Result := -1
  else if ATemp > 0 then
    Result := 1
  else
    Result := 0;
end;

function TQRepeatJobs.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQRepeatJobs.InternalPop: PQJob;
var
  ANode: TQRBNode;
  ATick: Int64;
  AJob: PQJob;
begin
  Result := nil;
  if FItems.Count = 0 then
    Exit;
  FLocker.Enter;
  try
    if FItems.Count > 0 then
    begin
      ATick := GetTimestamp;
      ANode := FItems.First;
      AJob := ANode.Data;
      // OutputDebugString(PWideChar('Result.NextTime='+IntToStr(AJob.NextTime)+',Current='+IntToStr(ATick)+',Delta='+IntToStr(AJob.NextTime-ATick)));
      if AJob.NextTime <= ATick then
      begin
        if AJob.Next <> nil then
          // 如果没有更多需要执行的作业，则删除结点，否则指向下一个
          ANode.Data := AJob.Next
        else
        begin
          ANode.Data := nil;
          FItems.Delete(ANode);
          ANode := FItems.First;
          if ANode <> nil then
            FFirstFireTime := PQJob(ANode.Data).NextTime
          else
            // 没有计划作业了，不需要了
            FFirstFireTime := 0;
        end;
        AJob.PopTime := ATick;
        if AJob.Runonce then
          Result := AJob
        else
        begin
          AJob.Next := nil;
          Result := JobPool.Pop;
          Result.Assign(AJob);
          Result.Source := AJob;
          if AJob.IsDelayRepeat then // 如果作业是延迟重复作业，则保证它排在后面
            AJob.NextTime := Int64($7FFFFFFFFFFFFFFF)
          else
            Inc(AJob.NextTime, AJob.Interval);
          // 重新插入作业
          ANode := FItems.Find(AJob);
          if ANode = nil then
          begin
            FItems.Insert(AJob);
            FFirstFireTime := PQJob(FItems.First.Data).NextTime;
          end
          else
          // 如果已经存在同一时刻的作业，则自己挂接到其它作业头部
          begin
            AJob.Next := PQJob(ANode.Data);
            ANode.Data := AJob; // 首个作业改为自己
          end;
        end;
      end;
    end
    else
      FFirstFireTime := 0;
  finally
    FLocker.Leave;
  end;
end;

function TQRepeatJobs.InternalPush(AJob: PQJob): Boolean;
var
  ANode: TQRBNode;
begin
  // 计算作业的下次执行时间
  AJob.UpdateNextTime;
  FLocker.Enter;
  try
    ANode := FItems.Find(AJob);
    if ANode = nil then
    begin
      FItems.Insert(AJob);
      FFirstFireTime := PQJob(FItems.First.Data).NextTime;
    end
    else
    // 如果已经存在同一时刻的作业，则自己挂接到其它作业头部，将来可以通过更改红黑树的实现来优化减少一次查询
    begin
      AJob.Next := PQJob(ANode.Data);
      ANode.Data := AJob; // 首个作业改为自己
    end;
    Result := True;
  finally
    FLocker.Leave;
  end;
end;

function TQRepeatJobs.Clear(AHandle: IntPtr): Boolean;
var
  ANode, ANext: TQRBNode;
  APriorJob, AJob, ANextJob: PQJob;
  ACanDelete: Boolean;
begin
  Result := false;
  FLocker.Enter;
  try
    ANode := FItems.First;
    while ANode <> nil do
    begin
      ANext := ANode.Next;
      AJob := ANode.Data;
      ACanDelete := True;
      APriorJob := nil;
      while AJob <> nil do
      begin
        ANextJob := AJob.Next;
        if IntPtr(AJob) = AHandle then
        begin
          if ANode.Data = AJob then
          begin
            ANode.Data := ANextJob;
            Assert(APriorJob = nil);
          end;
          if Assigned(APriorJob) then
            APriorJob.Next := ANextJob;
          AJob.Next := nil;
          FOwner.FreeJob(AJob);
          Result := True;
          Break;
        end
        else
        begin
          ACanDelete := false;
          APriorJob := AJob;
        end;
        AJob := ANextJob;
      end;
      if ACanDelete then
        FItems.Delete(ANode);
      ANode := ANext;
    end;
    if FItems.Count > 0 then
      FFirstFireTime := PQJob(FItems.First.Data).NextTime
    else
      FFirstFireTime := 0;
  finally
    FLocker.Leave;
  end;
end;

function TQRepeatJobs.ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
var
  ANode, ANext: TQRBNode;
  APriorJob, AJob, ANextJob: PQJob;
  ACanDelete: Boolean;
  function Accept(AJob: PQJob): Boolean;
  var
    P: PIntPtr;
  begin
    P := AHandles;
    Result := false;
    while IntPtr(P) < IntPtr(AHandles) do
    begin
      if (IntPtr(P^) and (not $03)) = IntPtr(AJob) then
      begin
        P^ := 0;
        Result := True;
        Exit;
      end;
      Inc(P);
    end;
  end;

begin
  Result := 0;
  FLocker.Enter;
  try
    ANode := FItems.First;
    while ANode <> nil do
    begin
      ANext := ANode.Next;
      AJob := ANode.Data;
      ACanDelete := True;
      APriorJob := nil;
      while AJob <> nil do
      begin
        ANextJob := AJob.Next;
        if Accept(AJob) then
        begin
          if ANode.Data = AJob then
            ANode.Data := ANextJob;
          if Assigned(APriorJob) then
            APriorJob.Next := ANextJob;
          AJob.Next := nil;
          FOwner.FreeJob(AJob);
          Inc(Result);
        end
        else
        begin
          ACanDelete := false;
          APriorJob := AJob;
        end;
        AJob := ANextJob;
      end;
      if ACanDelete then
        FItems.Delete(ANode);
      ANode := ANext;
    end;
    if FItems.Count > 0 then
      FFirstFireTime := PQJob(FItems.First.Data).NextTime
    else
      FFirstFireTime := 0;
  finally
    FLocker.Leave;
  end;
end;

{ TQWorker }

procedure TQWorker.AfterExecute;
begin
  Inc(FProcessed);
  FActiveJob.DoneTime := GetTimestamp;
  if Assigned(FOwner.FAfterExecute) then
  begin
    try
      FOwner.FAfterExecute(FActiveJob);
    except

    end;
  end;
  SetFlags(WORKER_CLEANING, True);
{$IFDEF DEBUGOUT}
  OutputDebugString(PChar(FThreadName + ':作业完成，执行清理过程'));
{$ENDIF}
  FActiveJob.Worker := nil;
  if not FActiveJob.Runonce then
  begin
    if FActiveJob.IsByPlan then
      FOwner.AfterPlanRun(FActiveJob, GetTimestamp - FActiveJob.StartTime)
    else
      FOwner.FRepeatJobs.AfterJobRun(FActiveJob,
        GetTimestamp - FActiveJob.StartTime);
    FActiveJob.Data := nil;
  end
  else
  begin
    if FActiveJob.IsSignalWakeup then
      FOwner.SignalWorkDone(FActiveJob, GetTimestamp - FActiveJob.StartTime)
    else if FActiveJob.IsLongtimeJob then
      AtomicDecrement(FOwner.FLongTimeWorkers)
    else if FActiveJob.IsGrouped then
      FActiveJobGroup.DoJobExecuted(FActiveJob);
  end;
  if Assigned(FActiveJob) then
    FOwner.FreeJob(FActiveJob);
  FActiveJobProc.Code := nil;
  FActiveJobProc.Data := nil;
  FActiveJobSource := nil;
  FActiveJobFlags := 0;
  FActiveJobGroup := nil;
  FTerminatingJob := nil;
  FFlags := FFlags and (not WORKER_EXECUTING);
end;

procedure TQWorker.ComNeeded(AInitFlags: Cardinal);
begin
{$IFDEF MSWINDOWS}
  if not ComInitialized then
  begin
    if AInitFlags = 0 then
      CoInitialize(nil)
    else
      CoInitializeEx(nil, AInitFlags);
    FFlags := FFlags or WORKER_COM_INITED;
  end;
{$ENDIF MSWINDOWS}
end;

constructor TQWorker.Create(AOwner: TQWorkers);
begin
  inherited Create(True);
  FOwner := AOwner;
  FTimeout := 1000;
  FreeOnTerminate := True;
  FEvent := TEvent.Create(nil, false, false, '');
end;

destructor TQWorker.Destroy;
begin
  FreeObject(FEvent);
  if Assigned(FExtObject) then
    FreeAndNil(FExtObject);
  inherited;
end;

procedure TQWorker.DoJob(AJob: PQJob);
begin
{$IFDEF UNICODE}
  if AJob.IsAnonWorkerProc then
    TQJobProcA(AJob.WorkerProc.ProcA)(AJob)
  else
{$ENDIF}
  begin
    if AJob.WorkerProc.Data <> nil then
{$IFDEF NEXTGEN}
      PQJobProc(@AJob.WorkerProc)^(AJob)
{$ELSE}
      AJob.WorkerProc.Proc(AJob)
{$ENDIF}
    else
      AJob.WorkerProc.ProcG(AJob);
  end;
end;

function TQWorker.WaitSignal(ATimeout: Cardinal; AByRepeatJob: Boolean)
  : TWaitResult;
var
  T: Int64;
begin
  if ATimeout > 1 then
  begin
    T := GetTimestamp;
    if Cardinal(ATimeout) > FOwner.FFireTimeout + FFireDelay - FTimeout then
      ATimeout := FOwner.FFireTimeout + FFireDelay - FTimeout;
    Result := FEvent.WaitFor(ATimeout);
    T := GetTimestamp - T;
    if Result = wrTimeout then
    begin
      Inc(FTimeout, T div 10);
      if AByRepeatJob then
        Result := wrSignaled;
    end;
  end
  else
    Result := wrSignaled;
end;

procedure TQWorker.Execute;
var
  wr: TWaitResult;
{$IFDEF MSWINDOWS}
  SyncEvent: TEvent;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  SyncEvent := TEvent.Create(nil, false, false, '');
{$IF RTLVersion>=21}
  FThreadName := IntToHex(IntPtr(HInstance), SizeOf(Pointer) shl 1) +
    '.QWorker.' + IntToStr(ThreadId);
  NameThreadForDebugging(FThreadName);
{$IFEND >=2010}
{$ENDIF}
  try
    SetFlags(WORKER_RUNNING, True);
    FLastActiveTime := GetTimestamp;
    FFireDelay := Random(FOwner.FFireTimeout shr 1);
{$IFDEF DEBUGOUT}
    OutputDebugString(PChar(FThreadName + ':工作者准备接受作业'));
{$ENDIF}
    while not(Terminated or FOwner.FTerminating) do
    begin
      SetFlags(WORKER_CLEANING, false);
{$IFDEF DEBUGOUT}
      OutputDebugString(PChar(FThreadName + ' :工作者正在等待作业'));
{$ENDIF}
      if FOwner.Enabled then
      begin
        if FOwner.FSimpleJobs.FFirst <> nil then
          wr := wrSignaled
        else if (FOwner.FRepeatJobs.FFirstFireTime <> 0) then
          wr := WaitSignal((FOwner.FRepeatJobs.FFirstFireTime - GetTimestamp)
            div 10, True)
        else
          wr := WaitSignal(FOwner.FFireTimeout, false);
      end
      else
        wr := WaitSignal(FOwner.FFireTimeout, false);
      if Terminated or FOwner.FTerminating then
      begin
{$IFDEF DEBUGOUT}
        OutputDebugString(PChar(FThreadName + ':工作者即将结束'));
{$ENDIF}
        Break;
      end;
      if wr = wrSignaled then
      begin
{$IFDEF DEBUGOUT}
        OutputDebugString(PChar(FThreadName + ':工作者接收到有作业需要处理信号'));
{$ENDIF}
        FPending := false;
        if (FOwner.Workers - AtomicIncrement(FOwner.FBusyCount) = 0) and
          (FOwner.Workers < FOwner.MaxWorkers) then
          FOwner.NewWorkerNeeded;
        repeat
          SetFlags(WORKER_LOOKUP, True);
          FActiveJob := FOwner.Popup;
          SetFlags(WORKER_LOOKUP, false);
          if FActiveJob <> nil then
          begin
            SetFlags(WORKER_ISBUSY, True);
            FTimeout := 0;
            FLastActiveTime := FActiveJob.PopTime;
            FActiveJob.Worker := Self;
            FActiveJobProc := FActiveJob.WorkerProc;
            // {$IFDEF NEXTGEN} PQJobProc(@FActiveJob.WorkerProc)^
            // {$ELSE} FActiveJob.WorkerProc.Proc {$ENDIF};
            // 为Clear(AObject)准备判断，以避免FActiveJob线程不安全
            FActiveJobData := FActiveJob.Data;
            if FActiveJob.IsSignalWakeup or (not FActiveJob.Runonce) then
              FActiveJobSource := FActiveJob.Source
            else
              FActiveJobSource := nil;
            if FActiveJob.IsGrouped then
              FActiveJobGroup := FActiveJob.Group
            else
              FActiveJobGroup := nil;
            FActiveJobFlags := FActiveJob.Flags;
            if FActiveJob.StartTime = 0 then
            begin
              FActiveJob.StartTime := FLastActiveTime;
              FActiveJob.FirstStartTime := FActiveJob.StartTime;
            end
            else
              FActiveJob.StartTime := FLastActiveTime;
            try
              FFlags := (FFlags or WORKER_EXECUTING) and (not WORKER_LOOKUP);
{$IFDEF DEBUGOUT}
              OutputDebugString
                (PChar(FThreadName + ':工作者执行作业 ' + IntToHex(IntPtr(FActiveJob),
                SizeOf(Pointer) shl 1)));
{$ENDIF}
              if FActiveJob.InMainThread then
{$IFDEF MSWINDOWS}
              begin
                if PostMessage(FOwner.FMainWorker, WM_APP, WPARAM(FActiveJob),
                  LPARAM(SyncEvent)) then
                  SyncEvent.WaitFor(INFINITE);
              end
{$ELSE}
              Synchronize(Self, FireInMainThread)
{$ENDIF}
              else
                DoJob(FActiveJob);
            except
              on E: Exception do
                if Assigned(FOwner.FOnError) then
                  FOwner.FOnError(FActiveJob, E, jesExecute);
            end;
            AfterExecute;
          end
          else
            FFlags := FFlags and (not WORKER_LOOKUP);
        until (FActiveJob = nil) or Terminated or FOwner.FTerminating or
          (not FOwner.Enabled);
        SetFlags(WORKER_ISBUSY, false);
        AtomicDecrement(FOwner.FBusyCount);
        // ThreadYield;
      end;
      if (FTimeout >= FOwner.FireTimeout + FFireDelay) then
      // 加一个随机延迟，以避免同时释放
      begin
        FOwner.WorkerTimeout(Self);
        if not IsFiring then
          FTimeout := 0;
      end;
    end;
  finally
    SetFlags(WORKER_RUNNING, false);
{$IFDEF DEBUGOUT}
    OutputDebugString(PChar(FThreadName + ':正在清理'));
{$ENDIF}
{$IFDEF MSWINDOWS}
    FreeObject(SyncEvent);
    if ComInitialized then
      CoUninitialize;
{$ENDIF}
    FOwner.WorkerTerminate(Self);
{$IFDEF DEBUGOUT}
    OutputDebugString(PChar(IntToStr(ThreadId) + ' -工作者退出'));
{$ENDIF}
  end;
end;

procedure TQWorker.FireInMainThread;
begin
  DoJob(FActiveJob);
end;

procedure TQWorker.ForceQuit;
var
  I: Integer;
  AThread: TThread;
begin
  // 警告：此函数会强制结束当前工作者，当前工作者的作业实际上被强制停止，可能会产生内存泄露
  AThread := Self;
  if ThreadExists(AThread.ThreadId) then
    AThread.Suspended := True;
  AThread.Terminate;
  TThread.Synchronize(nil, DoTerminate);
{$IFDEF MSWINDOWS}
  TerminateThread(Handle, $FFFFFFFF);
{$ENDIF}
  FOwner.WorkerTerminate(Self);
  if Assigned(FActiveJob) then
  begin
    AtomicDecrement(FOwner.FBusyCount);
    if not IsCleaning then
      AfterExecute;
  end;
  if FreeOnTerminate then
    FreeAndNil(AThread);
end;

function TQWorker.GetExtObject: TQWorkerExt;
begin
  if Assigned(FOwner.WorkerExtClass) and (not Assigned(FExtObject)) then
    FExtObject := FOwner.WorkerExtClass.Create(Self);
  Result := FExtObject;
end;

function TQWorker.GetFlags(AIndex: Integer): Boolean;
begin
  Result := ((FFlags and AIndex) <> 0);
end;

function TQWorker.GetIsIdle: Boolean;
begin
  Result := not IsBusy;
end;

procedure TQWorker.SetFlags(AIndex: Integer; AValue: Boolean);
begin
  if AValue then
    FFlags := FFlags or AIndex
  else
    FFlags := FFlags and (not AIndex);
end;

{ TQWorkers }

function TQWorkers.Post(AJob: PQJob): IntPtr;
begin
  Result := 0;
  if (not FTerminating) and (Assigned(AJob.WorkerProc.Proc)
{$IFDEF UNICODE} or Assigned(AJob.WorkerProc.ProcA){$ENDIF}) then
  begin
    if AJob.Runonce and (AJob.FirstDelay = 0) then
    begin
      if FSimpleJobs.Push(AJob) then
      begin
        Result := IntPtr(AJob);
        LookupIdleWorker(True);
      end;
    end
    else if AJob.IsByPlan then
    begin
      if FPlanJobs.Push(AJob) then
      begin
        Result := IntPtr(AJob) or JOB_HANDLE_PLAN_MASK;
        PlanCheckNeeded;
      end;
    end
    else if FRepeatJobs.Push(AJob) then
    begin
      Result := IntPtr(AJob) or JOB_HANDLE_REPEAT_MASK;
      LookupIdleWorker(false);
    end;
  end
  else
  begin
    AJob.Next := nil;
    FreeJob(AJob);
  end;
end;

function TQWorkers.Post(AProc: TQJobProc; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, True, ARunInMainThread);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  Result := Post(AJob);
end;

function TQWorkers.Post(AProc: TQJobProc; AInterval: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
  AJob.Interval := AInterval;
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  Result := Post(AJob);
end;

function TQWorkers.Post(AProc: TQJobProcG; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Post(TQJobProc(MakeJobProc(AProc)), AData, ARunInMainThread,
    AFreeType);
end;

{$IFDEF UNICODE}

function TQWorkers.Post(AProc: TQJobProcA; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, True, ARunInMainThread);
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  Result := Post(AJob);
end;
{$ENDIF}

function TQWorkers.Clear(AObject: Pointer; AMaxTimes: Integer;
  AWaitRunningDone: Boolean): Integer;
var
  ACleared: Integer;
  AWaitParam: TWorkerWaitParam;
  function ClearSignalJobs: Integer;
  var
    I: Integer;
    AJob, ANext, APrior: PQJob;
    ASignal: PQSignal;
  begin
    Result := 0;
    FLocker.Enter;
    try
      for I := 0 to FMaxSignalId - 1 do
      begin
        ASignal := FSignalJobs[I];
        AJob := ASignal.First;
        APrior := nil;
        while Assigned(AJob) and (AMaxTimes <> 0) do
        begin
          ANext := AJob.Next;
          if IsObjectJob(AJob, AObject) then
          begin
            if ASignal.First = AJob then
              ASignal.First := ANext;
            if Assigned(APrior) then
              APrior.Next := ANext;
            AJob.Next := nil;
            FreeJob(AJob);
            Dec(AMaxTimes);
            Inc(Result);
          end
          else
            APrior := AJob;
          AJob := ANext;
        end;
        if AMaxTimes = 0 then
          Exit;
      end;
    finally
      FLocker.Leave;
    end;
  end;

begin
  Result := 0;
  if Self <> nil then
  begin
    ACleared := FSimpleJobs.Clear(AObject, AMaxTimes);
    Inc(Result, ACleared);
    Dec(AMaxTimes, ACleared);
    if AMaxTimes = 0 then
      Exit;
    ACleared := FRepeatJobs.Clear(AObject, AMaxTimes);
    Inc(Result, ACleared);
    Dec(AMaxTimes, ACleared);
    if AMaxTimes = 0 then
      Exit;
    ACleared := ClearSignalJobs;
    Inc(Result, ACleared);
    if AMaxTimes = 0 then
      Exit;
    ACleared := FPlanJobs.Clear(AObject, AMaxTimes);
    Inc(Result, ACleared);
    Dec(AMaxTimes, ACleared);
    if AMaxTimes = 0 then
      Exit;
    AWaitParam.WaitType := 0;
    AWaitParam.Bound := AObject;
    WaitRunningDone(AWaitParam, not AWaitRunningDone);
  end;
end;

function TQWorkers.At(AProc: TQJobProc; const ADelay, AInterval: Int64;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  AJob.Interval := AInterval;
  AJob.FirstDelay := ADelay;
  Result := Post(AJob);
end;

function TQWorkers.At(AProc: TQJobProc; const ATime: TDateTime;
  const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
  ADelay: Int64;
  ANow: TDateTime;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  AJob.Interval := AInterval;
  ANow := Now;
  if Trunc(ATime) = 0 then // 如果没有传递日期部分，则不比较日期
    ANow := ANow - Trunc(ANow);
  // 检查时间差
  if ANow > ATime then // 时间已过
  begin
    if AInterval > 0 then // 重复作业，计算下次的执行时间
    begin
      ADelay := MilliSecondsBetween(ATime, ANow) * 10;
      ADelay := (ADelay div AInterval + 1) * AInterval - ADelay;
    end
    else // 作业已经错过执行期，并且不是重复作业，忽略掉
    begin
      JobPool.Push(AJob);
      Result := 0;
      Exit;
    end;
  end
  else if ANow < ATime then
    ADelay := MilliSecondsBetween(ANow, ATime) * 10
  else
    ADelay := 0;
  AJob.FirstDelay := ADelay;
  Result := Post(AJob);
end;

class function TQWorkers.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProc; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
begin
  Result := TQForJobs.For(AStartIndex, AStopIndex, AWorkerProc, AMsgWait, AData,
    AFreeType);
end;

class function TQWorkers.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcG; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
begin
  Result := TQForJobs.For(AStartIndex, AStopIndex, AWorkerProc, AMsgWait, AData,
    AFreeType);
end;
{$IFDEF UNICODE}

class function TQWorkers.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcA; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
begin
  Result := TQForJobs.For(AStartIndex, AStopIndex, AWorkerProc, AMsgWait, AData,
    AFreeType);
end;

function TQWorkers.At(AProc: TQJobProcA; const ATime: TDateTime;
  const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
  ADelay: Int64;
  ANow, ATemp: TDateTime;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  AJob.Interval := AInterval;
  // ATime我们只要时间部分，日期忽略
  ANow := Now;
  ANow := ANow - Trunc(ANow);
  ATemp := ATime - Trunc(ATime);
  if ANow > ATemp then // 好吧，今天的点已经过了，算明天
    ADelay := Trunc(((1 + ANow) - ATemp) * Q1Day) // 延迟的时间，单位为0.1ms
  else
    ADelay := Trunc((ATemp - ANow) * Q1Day);
  AJob.FirstDelay := ADelay;
  Result := Post(AJob);
end;
{$ENDIF}

procedure TQWorkers.AfterPlanRun(AJob: PQJob; AUsedTime: Int64);
begin
  AJob := PQJob(AJob.PlanJob);
  AJob.AfterRun(AUsedTime);
  FPlanJobs.FLocker.Enter;
  try
    Dec(AJob.ExtData.AsPlan.Runnings);
  finally
    FPlanJobs.FLocker.Leave;
  end;
end;

function TQWorkers.Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer;
  AWaitRunningDone: Boolean): Integer;
var
  ACleared: Integer;
  AWaitParam: TWorkerWaitParam;
  function ClearSignalJobs: Integer;
  var
    I: Integer;
    AJob, ANext, APrior: PQJob;
    ASignal: PQSignal;
  begin
    Result := 0;
    FLocker.Enter;
    try
      for I := 0 to FMaxSignalId - 1 do
      begin
        ASignal := FSignalJobs[I];
        AJob := ASignal.First;
        APrior := nil;
        while Assigned(AJob) and (AMaxTimes <> 0) do
        begin
          ANext := AJob.Next;
          if SameWorkerProc(AJob.WorkerProc, AProc) and
            ((AData = Pointer(-1)) or (AJob.Data = AData)) then
          begin
            if ASignal.First = AJob then
              ASignal.First := ANext;
            if Assigned(APrior) then
              APrior.Next := ANext;
            AJob.Next := nil;
            FreeJob(AJob);
            Inc(Result);
            Dec(AMaxTimes);
          end
          else
            APrior := AJob;
          AJob := ANext;
        end;
        if AMaxTimes = 0 then
          Break;
      end;
    finally
      FLocker.Leave;
    end;
  end;

begin
  Result := 0;
  if Self <> nil then
  begin
    ACleared := FSimpleJobs.Clear(AProc, AData, AMaxTimes);
    Dec(AMaxTimes, ACleared);
    Inc(Result, ACleared);
    if AMaxTimes = 0 then
      Exit;
    ACleared := FRepeatJobs.Clear(AProc, AData, AMaxTimes);
    Dec(AMaxTimes, ACleared);
    Inc(Result, ACleared);
    if AMaxTimes = 0 then
      Exit;
    ACleared := ClearSignalJobs; // Don dec AMaxTimes in current line
    Inc(Result, ACleared);
    if AMaxTimes = 0 then
      Exit;
    ACleared := FPlanJobs.Clear(AProc, AData, AMaxTimes);
    Dec(AMaxTimes, ACleared);
    Inc(Result, ACleared);
    if AMaxTimes = 0 then
      Exit;
    AWaitParam.WaitType := 1;
    AWaitParam.Data := AData;
    AWaitParam.WorkerProc := TMethod(AProc);
    WaitRunningDone(AWaitParam, not AWaitRunningDone);
  end;
end;

procedure TQWorkers.ClearWorkers;
var
  I: Integer;
  AInMainThread: Boolean;
  function WorkerExists: Boolean;
  var
    J: Integer;
  begin
    Result := false;
    FLocker.Enter;
    try
      J := FWorkerCount - 1;
      while J >= 0 do
      begin
        if ThreadExists(FWorkers[J].ThreadId) then
        begin
          Result := True;
          Break;
        end;
        Dec(J);
      end;
    finally
      FLocker.Leave;
    end;
  end;
  procedure SetEvents;
  var
    I, C: Integer;
  begin
    C := 0;
    FLocker.Enter;
    try
      FRepeatJobs.FFirstFireTime := 0;
      for I := 0 to FWorkerCount - 1 do
      begin
        if ThreadExists(FWorkers[I].ThreadId) then
        // 在 DLL 中，线程可能被 Windows 直接结束掉
        begin
          FWorkers[I].FEvent.SetEvent;
          Inc(C);
        end;
      end;
    finally
      FLocker.Leave;
      if C = 0 then
        FTerminateEvent.SetEvent;
    end;
  end;

{$IFDEF MSWINDOWS}
  procedure ProcessMainThreadJobs;
  var
    AMsg: MSG;
    ACopy: TMessage;
  begin
    while PeekMessage(AMsg, FMainWorker, WM_APP, WM_APP, PM_REMOVE) do
    begin
      ACopy.MSG := AMsg.message;
      ACopy.WPARAM := AMsg.WPARAM;
      ACopy.LPARAM := AMsg.LPARAM;
      ACopy.Result := 0;
      DoMainThreadWork(ACopy);
    end;
  end;
{$ENDIF}

begin
  FTerminating := True;
  if not Assigned(FTerminateEvent) then
    FTerminateEvent := TEvent.Create(nil, True, false, '');
  SetEvents;
{$IFDEF MSWINDOWS}
  repeat
    ProcessMainThreadJobs;
  until FTerminateEvent.WaitFor(10) = wrSignaled;
{$ELSE}
  FTerminateEvent.WaitFor(INFINITE);
{$ENDIF}
  FreeAndNil(FTerminateEvent);
  while FWorkerCount > 0 do
    FWorkers[0].ForceQuit;
  {
    AInMainThread := GetCurrentThreadId = MainThreadId;
    while (FWorkerCount > 0) and WorkerExists do
    begin
    SetEvents;
    if AInMainThread then
    ProcessAppMessage
    else
    Sleep(10);
    end;
    for I := 0 to FWorkerCount - 1 do
    begin
    if FWorkers[I] <> nil then
    FreeObject(FWorkers[I]);
    end;
    FWorkerCount := 0;
  }
end;

constructor TQWorkers.Create(AMinWorkers: Integer);
var
  ACpuCount: Integer;
  I: Integer;

begin
  FSimpleJobs := TQSimpleJobs.Create(Self);
  FPlanJobs := TQSimpleJobs.Create(Self);
  FRepeatJobs := TQRepeatJobs.Create(Self);
  SetLength(FSignalJobs, 32); // 默认32项Signal，然后成倍按需增加
  FSignalNameList := TList.Create;
  FFireTimeout := DEFAULT_FIRE_TIMEOUT;
  FStaticThread := TStaticThread.Create;
  ACpuCount := GetCPUCount;
  if AMinWorkers < 1 then
    FMinWorkers := 2
  else
    FMinWorkers := AMinWorkers;
  // 最少工作者为2个
  FMaxWorkers := (ACpuCount shl 1) + 1;
  if FMaxWorkers <= FMinWorkers then
    FMaxWorkers := (FMinWorkers shl 1) + 1;
  FLocker := TCriticalSection.Create;
  FTerminating := false;
  // 创建默认工作者
  FWorkerCount := 0;
  SetLength(FWorkers, FMaxWorkers + 1);
  for I := 0 to FMinWorkers - 1 do
    FWorkers[I] := CreateWorker(True);
  for I := 0 to FMinWorkers - 1 do
  begin
    FWorkers[I].FEvent.SetEvent;
    FWorkers[I].Suspended := false;
  end;
  FMaxLongtimeWorkers := (FMaxWorkers shr 1);
{$IFDEF MSWINDOWS}
  FMainWorker := AllocateHWnd(DoMainThreadWork);
{$ENDIF}
  FStaticThread.Suspended := false;
  FSignalQueue := TQSignalQueue.Create(Self);
end;

function TQWorkers.CreateWorker(ASuspended: Boolean): TQWorker;
begin
  if FWorkerCount < FMaxWorkers then
  begin
    Result := TQWorker.Create(Self);
    FWorkers[FWorkerCount] := Result;
{$IFDEF MSWINDOWS}
    SetThreadCPU(Result.Handle, FWorkerCount mod GetCPUCount);
{$ELSE}
    SetThreadCPU(Result.ThreadId, FWorkerCount mod GetCPUCount);
{$ENDIF}
    Inc(FWorkerCount);
    if not ASuspended then
    begin
      Result.FPending := True;
      Result.FEvent.SetEvent;
      Result.Suspended := false;
    end;
  end
  else
    Result := nil;
end;

function TQWorkers.Delay(AProc: TQJobProc; ADelay: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType;
  ARepeat: Boolean): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, not ARepeat, ARunInMainThread);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  if ADelay > 0 then
    AJob.FirstDelay := ADelay;
  AJob.IsDelayRepeat := ARepeat;
  Result := Post(AJob);
end;

{$IFDEF UNICODE}

function TQWorkers.Delay(AProc: TQJobProcA; ADelay: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType;
  ARepeat: Boolean): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, not ARepeat, ARunInMainThread);
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  if ADelay > 0 then
    AJob.FirstDelay := ADelay;
  AJob.IsDelayRepeat := ARepeat;
  Result := Post(AJob);
end;

{$ENDIF}

function TQWorkers.Delay(AProc: TQJobProcG; ADelay: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType;
  ARepeat: Boolean): IntPtr;
begin
  Result := Delay(TQJobProc(MakeJobProc(AProc)), ADelay, AData,
    ARunInMainThread, AFreeType, ARepeat);
end;

destructor TQWorkers.Destroy;
var
  I: Integer;
begin
  ClearWorkers;
  FLocker.Enter;
  try
    FreeObject(FSimpleJobs);
    FreeObject(FPlanJobs);
    FreeObject(FRepeatJobs);
    for I := 0 to FMaxSignalId - 1 do
    begin
      if Assigned(FSignalJobs[I].First) then
        FreeJob(FSignalJobs[I].First);
      Dispose(FSignalJobs[I]);
    end;
    SetLength(FSignalJobs, 0);
    FreeAndNil(FSignalQueue);
    FreeAndNil(FSignalNameList);
  finally
    FreeObject(FLocker);
  end;

{$IFDEF MSWINDOWS}
  DeallocateHWnd(FMainWorker);
  if IsLibrary or ModuleIsLib then
  begin
    TerminateThread(FStaticThread.Handle, 1);
    FreeAndNil(TStaticThread(FStaticThread).FEvent);
    FreeAndNil(FStaticThread);
  end
  else
{$ENDIF}
  begin
    FStaticThread.Terminate;
    FStaticThread.WaitFor;
    FreeAndNil(FStaticThread);
  end;
  inherited;
end;

procedure TQWorkers.DisableWorkers;
begin
  AtomicIncrement(FDisableCount);
end;

procedure TQWorkers.DoCustomFreeData(AFreeType: TQJobDataFreeType;
  const AData: Pointer);
begin
  if Assigned(FOnCustomFreeData) then
    FOnCustomFreeData(Self, AFreeType, AData);
end;

procedure TQWorkers.DoJobFree(ATable: TQHashTable; AHash: Cardinal;
  AData: Pointer);
var
  ASignal: PQSignal;
begin
  ASignal := AData;
  if ASignal.First <> nil then
    FreeJob(ASignal.First);
  Dispose(ASignal);
end;
{$IFDEF MSWINDOWS}

procedure TQWorkers.DoMainThreadWork(var AMsg: TMessage);
var
  AJob: PQJob;
begin
  if AMsg.MSG = WM_APP then
  begin
    AJob := PQJob(AMsg.WPARAM);
    try
      AJob.Worker.DoJob(AJob);
    except
      on E: Exception do
      begin
        if Assigned(FOnError) then
          FOnError(AJob, E, jesExecute);
      end;
    end;
    if AMsg.LPARAM <> 0 then
      TEvent(AMsg.LPARAM).SetEvent;
  end
  else
    AMsg.Result := DefWindowProc(FMainWorker, AMsg.MSG, AMsg.WPARAM,
      AMsg.LPARAM);
end;

{$ENDIF}

procedure TQWorkers.DoPlanCheck(AJob: PQJob);
var
  AItem, ATimeoutJob, APrior, ANext: PQJob;
  ATime: TDateTime;
  ATimeStamp: Int64;
  APlan: PQJobPlanData;
  ACheckResult: TQPlanTimeoutCheckResult;
begin
  ATime := Now;
  ATimeStamp := GetTimestamp;
  ATimeoutJob := nil;
  APrior := nil;
  FPlanJobs.FLocker.Enter;
  try
    if not Assigned(FPlanJobs.FFirst) then
    begin
      ClearSingleJob(FPlanCheckJob, false);
      FPlanCheckJob := 0;
    end
    else
    begin
      AItem := FPlanJobs.FFirst;
      while Assigned(AItem) do
      begin
        APlan := AItem.ExtData.AsPlan;
        if ATime > APlan.NextTime then // 检查任务是否错过执行
          ACheckResult := pcrOk
        else
          ACheckResult := APlan.Plan.Timeout(ATime);
        case ACheckResult of
          pcrOk:
            begin
              APlan.Plan.LastTime := ATime;
              APlan.NextTime := APlan.Plan.NextTime;
              AJob := JobPool.Pop;
              AJob.Assign(AItem);
              AJob.Source := AItem;
              AJob.Data := AItem.ExtData.AsPlan.OriginData;
              AJob.IsByPlan := True;
              AJob.FreeType := AItem.ExtData.AsPlan.DataFreeType;
              AJob.PlanJob := AItem;
              AItem.PopTime := ATimeStamp;
              Inc(APlan.Runnings);
              if not FSimpleJobs.Push(AJob) then
              begin
                JobPool.Push(AJob);
                Break;
              end;
            end;
          pcrExpired:
            begin
              if APlan.Runnings = 0 then
              begin
                ANext := AItem.Next;
                if AItem = FPlanJobs.FFirst then
                  FPlanJobs.FFirst := ANext;
                if AItem = FPlanJobs.FLast then
                  FPlanJobs.FLast := APrior;
                AItem.Next := ATimeoutJob;
                ATimeoutJob := AItem;
                if Assigned(APrior) then
                  APrior.Next := ANext;
                AItem := ANext;
                Continue;
              end;
            end;
        end;
        APrior := AItem;
        AItem := AItem.Next;
      end;
    end;
  finally
    FPlanJobs.FLocker.Leave;
    if Assigned(ATimeoutJob) then
      FreeJob(ATimeoutJob);
  end;
end;

procedure TQWorkers.EnableWorkers;
var
  ANeedCount: Integer;
begin
  if AtomicDecrement(FDisableCount) = 0 then
  begin
    if (FSimpleJobs.Count > 0) or (FRepeatJobs.Count > 0) then
    begin
      ANeedCount := FSimpleJobs.Count + FRepeatJobs.Count;
      while ANeedCount > 0 do
      begin
        if not LookupIdleWorker(True) then
          Break;
        Dec(ANeedCount);
      end;
    end;
  end;
end;

function TQWorkers.EnumJobStates: TQJobStateArray;
var
  AJob: PQJob;
  I: Integer;
  ARunnings: TQJobStateArray;
  AStampDelta: Int64;
  ATimeDelta: TDateTime;
  procedure EnumSimpleJobs(ASimpleJobs: TQSimpleJobs);
  var
    AFirst: PQJob;
  begin
    I := Length(Result);
    AFirst := ASimpleJobs.PopAll;
    AJob := AFirst;
    SetLength(Result, 4096);
    while AJob <> nil do
    begin
      if I >= Length(Result) then
        SetLength(Result, Length(Result) + 4096);
      Assert(AJob.Handle <> 0);
      Result[I].Handle := AJob.Handle;
      Result[I].Proc := AJob.WorkerProc;
{$IFDEF UNICODE}
      if AJob.IsAnonWorkerProc then
      begin
        Result[I].Proc.ProcA := nil;
        TQJobProcA(Result[I].Proc.ProcA) := TQJobProcA(AJob.WorkerProc.ProcA);
      end;
{$ENDIF}
      Result[I].Flags := AJob.Flags;
      Result[I].PushTime := AJob.PushTime;
      if AJob.IsByPlan then
      begin
        Result[I].Plan := AJob.ExtData.AsPlan.Plan;
        Result[I].Runs := AJob.Runs;
        Result[I].PopTime := AJob.PopTime;
        Result[I].AvgTime := AJob.AvgTime;
        Result[I].TotalTime := AJob.TotalUsedTime;
        Result[I].MaxTime := AJob.MaxUsedTime;
        Result[I].MinTime := AJob.MinUsedTime;
        Result[I].NextTime := AStampDelta + MilliSecondsBetween
          (AJob.ExtData.AsPlan.Plan.NextTime, ATimeDelta) * 10;
      end;
      AJob := AJob.Next;
      Inc(I);
    end;
    ASimpleJobs.Repush(AFirst);
    SetLength(Result, I);
  end;
  procedure EnumRepeatJobs;
  var
    ANode: TQRBNode;
    ATemp: TQJobStateArray;
    L: Integer;
  begin
    I := 0;
    FRepeatJobs.FLocker.Enter;
    try
      ANode := FRepeatJobs.FItems.First;
      if FRepeatJobs.Count < 4 then
        SetLength(ATemp, 4)
      else
        SetLength(ATemp, FRepeatJobs.Count);
      while ANode <> nil do
      begin
        AJob := ANode.Data;
        while Assigned(AJob) do
        begin
          Assert(AJob.Handle <> 0);
          if I = Length(ATemp) then
            SetLength(ATemp, I shl 1);
          ATemp[I].Handle := AJob.Handle;
          ATemp[I].Proc := AJob.WorkerProc;
{$IFDEF UNICODE}
          if AJob.IsAnonWorkerProc then
          begin
            ATemp[I].Proc.ProcA := nil;
            TQJobProcA(ATemp[I].Proc.ProcA) := TQJobProcA(AJob.WorkerProc.ProcA)
          end;
{$ENDIF}
          ATemp[I].Flags := AJob.Flags;
          ATemp[I].Runs := AJob.Runs;
          ATemp[I].PushTime := AJob.PushTime;
          ATemp[I].PopTime := AJob.PopTime;
          ATemp[I].AvgTime := AJob.AvgTime;
          ATemp[I].TotalTime := AJob.TotalUsedTime;
          ATemp[I].MaxTime := AJob.MaxUsedTime;
          ATemp[I].MinTime := AJob.MinUsedTime;
          ATemp[I].NextTime := AJob.NextTime;
          AJob := AJob.Next;
          Inc(I);
        end;
        ANode := ANode.Next;
      end;
      SetLength(ATemp, I);
    finally
      FRepeatJobs.FLocker.Leave;
    end;
    if I > 0 then
    begin
      L := Length(Result);
      SetLength(Result, Length(Result) + I);
      Move(ATemp[0], Result[L], I * SizeOf(TQJobState));
    end;
  end;
  procedure EnumSignalJobs;
  var
    ATemp: TQJobStateArray;
    ASignal: PQSignal;
    L: Integer;
  begin
    L := 0;
    I := 0;
    FLocker.Enter;
    try
      SetLength(ATemp, 4096);
      while I < FMaxSignalId do
      begin
        ASignal := FSignalJobs[I];
        AJob := ASignal.First;
        while Assigned(AJob) do
        begin
          if L >= Length(ATemp) then
            SetLength(ATemp, Length(ATemp) + 4096);
          ATemp[L].Handle := AJob.Handle;
          ATemp[L].Proc := AJob.WorkerProc;
{$IFDEF UNICODE}
          if AJob.IsAnonWorkerProc then
          begin
            ATemp[I].Proc.ProcA := nil;
            TQJobProcA(ATemp[I].Proc.ProcA) := TQJobProcA(AJob.WorkerProc.ProcA)
          end;
{$ENDIF}
          ATemp[L].Runs := AJob.Runs;
          ATemp[L].Flags := AJob.Flags;
          ATemp[L].PushTime := AJob.PushTime;
          ATemp[L].PopTime := AJob.PopTime;
          ATemp[L].AvgTime := AJob.AvgTime;
          ATemp[L].TotalTime := AJob.TotalUsedTime;
          ATemp[L].MaxTime := AJob.MaxUsedTime;
          ATemp[L].MinTime := AJob.MinUsedTime;
          AJob := AJob.Next;
          Inc(L);
        end;
        Inc(I);
      end;
    finally
      FLocker.Leave;
    end;
    if L > 0 then
    begin
      I := Length(Result);
      SetLength(Result, Length(Result) + L);
      Move(ATemp[0], Result[I], L * SizeOf(TQJobState));
    end;
  end;
  procedure CheckRunnings;
  var
    C: Integer;
    J: Integer;
    AFound: Boolean;
  begin
    DisableWorkers;
    C := 0;
    FLocker.Enter;
    try
      SetLength(ARunnings, FWorkerCount);
      I := 0;
      while I < FWorkerCount do
      begin
        if FWorkers[I].IsExecuting then
        begin
          ARunnings[C].Handle := FWorkers[I].FActiveJob.Handle;
          ARunnings[C].Proc := FWorkers[I].FActiveJobProc;
          ARunnings[C].Flags := FWorkers[I].FActiveJobFlags;
          ARunnings[C].IsRunning := True;
          ARunnings[C].EscapedTime := GetTimestamp - FWorkers[I]
            .FLastActiveTime;
          ARunnings[C].PopTime := FWorkers[I].FLastActiveTime;
          Inc(C);
        end;
        Inc(I);
      end;
    finally
      FLocker.Leave;
      EnableWorkers;
    end;
    SetLength(ARunnings, C);
    I := 0;
    while I < C do
    begin
      AFound := false;
      for J := 0 to High(Result) do
      begin
        if ARunnings[I].Handle = Result[J].Handle then
        begin
          AFound := True;
          Break;
        end;
      end;
      if not AFound then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[Length(Result) - 1] := ARunnings[I];
      end;
      Inc(I);
    end;
  end;

  function IsRunning(AHandle: IntPtr): Boolean;
  var
    J: Integer;
  begin
    AHandle := AHandle and (not $03);
    Result := false;
    for J := 0 to High(ARunnings) do
    begin
      if AHandle = (ARunnings[J].Handle and (not $03)) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

begin
  ATimeDelta := Now;
  AStampDelta := GetTimestamp;
  SetLength(Result, 0);
  EnumSimpleJobs(FSimpleJobs);
  EnumSimpleJobs(FPlanJobs);
  EnumRepeatJobs;
  EnumSignalJobs;
  CheckRunnings;
  for I := 0 to High(Result) do
    Result[I].IsRunning := IsRunning(Result[I].Handle);
end;

function TQWorkers.EnumWorkerStatus: TQWorkerStatus;
var
  I: Integer;
  function GetMethodName(AMethod: TMethod): QStringW;
  var
    AObjName, AMethodName: QStringW;
{$IFDEF USE_MAP_SYMBOLS}
    ALoc: TQSymbolLocation;
{$ENDIF}
  begin
    if AMethod.Data <> nil then
    begin
      try
        AObjName := TObject(TObject(AMethod.Data)).ClassName;
{$IFDEF USE_MAP_SYMBOLS}
        if LocateSymbol(AMethod.Code, ALoc) then
        begin
          Result := ALoc.FunctionName;
          Exit;
        end
        else
          AMethodName := TObject(AMethod.Data).MethodName(AMethod.Code);
{$ELSE}
        AMethodName := TObject(AMethod.Data).MethodName(AMethod.Code);
{$ENDIF}
      except
        AObjName := IntToHex(NativeInt(AMethod.Data), SizeOf(Pointer) shl 1);
      end;
      if Length(AObjName) = 0 then
        AObjName := IntToHex(NativeInt(AMethod.Data), SizeOf(Pointer) shl 1);
      if Length(AMethodName) = 0 then
        AMethodName := IntToHex(NativeInt(AMethod.Code), SizeOf(Pointer) shl 1);
      Result := AObjName + '::' + AMethodName;
    end
    else if AMethod.Data <> nil then
      Result := IntToHex(NativeInt(AMethod.Code), SizeOf(Pointer) shl 1)
    else
      SetLength(Result, 0);
  end;

begin
  DisableWorkers;
  FLocker.Enter;
  try
    SetLength(Result, Workers);
    for I := 0 to Workers - 1 do
    begin
      Result[I].Processed := FWorkers[I].FProcessed;
      Result[I].ThreadId := FWorkers[I].ThreadId;
      Result[I].IsIdle := FWorkers[I].IsIdle;
      Result[I].LastActive := FWorkers[I].FLastActiveTime;
      Result[I].Timeout := FWorkers[I].FTimeout;
      if not Result[I].IsIdle then
      begin
        Result[I].ActiveJob :=
          GetMethodName(TMethod(FWorkers[I].FActiveJobProc));
        if Assigned(GetThreadStackInfo) then
          Result[I].Stacks := GetThreadStackInfo(FWorkers[I]);
      end;
    end;
  finally
    FLocker.Leave;
    EnableWorkers;
  end;
end;

function CompareName(S1, S2: QStringW): Integer; inline;
begin
  Result := {$IFDEF UNICODE}CompareStr(S1, S2){$ELSE}
    WideCompareStr(S1, S2){$ENDIF};
end;

function DoSignalNameCompare(P1, P2: Pointer): Integer;
begin
  Result := CompareName(PQSignal(P1).Name, PQSignal(P2).Name);
end;

function TQWorkers.FindSignal(const AName: QStringW;
  var AIndex: Integer): Boolean;
var
  L, H, I, C: Integer;
  ASignal: PQSignal;
begin
  L := 0;
  H := FSignalNameList.Count - 1;
  Result := false;
  while L <= H do
  begin
    I := (L + H) shr 1;
    ASignal := FSignalNameList[I];
    C := CompareName(ASignal.Name, AName);
    if C < 0 then
      L := I + 1
    else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
        L := I;
        Break;
      end;
    end;
  end;
  AIndex := L;
end;

procedure TQWorkers.FireSignalJob(AData: PQSignalQueueItem);
var
  AJob, ACopy: PQJob;
  ASignal: PQSignal;
  AFireCount: Integer;
begin
  AData.FireCount := 0;
  AFireCount := 0;
  AtomicIncrement(AData.RefCount);
  FLocker.Enter;
  if (AData.Id >= 1) and (AData.Id <= FMaxSignalId) then
  begin
    ASignal := FSignalJobs[AData.Id - 1];
    Inc(ASignal.Fired);
    AJob := ASignal.First;
    while AJob <> nil do
    begin
      ACopy := JobPool.Pop;
      ACopy.Assign(AJob);
      JobInitialize(ACopy, AData.Data, AData.FreeType, True, AJob.InMainThread);
      ACopy.SignalData := AData;
      AtomicIncrement(AData.FireCount);
      Inc(AFireCount);
      ACopy.Source := AJob;
      if not FSimpleJobs.Push(ACopy) then
        Break;
      AJob := AJob.Next;
    end;
  end;
  FLocker.Leave;
  if AFireCount = 0 then
    SignalQueue.SingalJobDone(AData)
  else
    LookupIdleWorker(false);
end;

procedure TQWorkers.FreeJob(AJob: PQJob);
var
  ANext: PQJob;
  AFreeData: Boolean;
begin
  AFreeData := false;
  CheckWaitChain(AJob);
  while AJob <> nil do
  begin
    ANext := AJob.Next;
    if AJob.PopTime = 0 then
    begin
      if Assigned(FBeforeCancel) then
      begin
        try
          FBeforeCancel(AJob);
        except

        end;
      end;
    end;
    if AJob.IsSignalWakeup and Assigned(AJob.SignalData) then
    begin
      if AtomicDecrement(PQSignalQueueItem(AJob.SignalData).FireCount) = 0 then
        SignalQueue.SingalJobDone(AJob.SignalData);
    end
    else
      AFreeData := AJob.IsDataOwner;
    if (AJob.Data <> nil) and AFreeData then
      FreeJobData(AJob.Data, AJob.FreeType);
    JobPool.Push(AJob);
    AJob := ANext;
  end;
end;

procedure TQWorkers.FreeJobData(AData: Pointer; AFreeType: TQJobDataFreeType);
begin
  if AData <> nil then
  begin
    try
      case AFreeType of
        jdfFreeAsObject:
          FreeObject(TObject(AData));
        jdfFreeAsSimpleRecord:
          Dispose(AData);
        jdfFreeAsInterface:
          IUnknown(AData)._Release
      else
        DoCustomFreeData(AFreeType, AData);
      end;
    except
      on E: Exception do
        if Assigned(FOnError) then
          FOnError(nil, E, jesFreeData);
    end;
  end;
end;

function TQWorkers.GetBusyCount: Integer;
begin
  Result := FBusyCount;
end;

function TQWorkers.GetEnabled: Boolean;
begin
  Result := (FDisableCount = 0);
end;

function TQWorkers.GetIdleWorkers: Integer;
begin
  Result := FWorkerCount - BusyWorkers;
end;

function TQWorkers.GetNextRepeatJobTime: Int64;
begin
  Result := FRepeatJobs.FFirstFireTime;
end;

function TQWorkers.GetOutWorkers: Boolean;
begin
  Result := (FBusyCount = MaxWorkers);
end;

function TQWorkers.GetTerminating: Boolean;
begin
  Result := FTerminating or AppTerminated;
end;

function TQWorkers.HandleToJob(const AHandle: IntPtr): PQJob;
begin
  Result := PQJob(AHandle and (not IntPtr(3)));
end;

function TQWorkers.LongtimeJob(AProc: TQJobProc; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  if AtomicIncrement(FLongTimeWorkers) <= FMaxLongtimeWorkers then
  begin
    AJob := JobPool.Pop;
    JobInitialize(AJob, AData, AFreeType, True, false);
    AJob.SetFlags(JOB_LONGTIME, True);
{$IFDEF NEXTGEN}
    PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
    AJob.WorkerProc.Proc := AProc;
{$ENDIF}
    Result := Post(AJob);
  end
  else
  begin
    AtomicDecrement(FLongTimeWorkers);
    Result := 0;
  end;
end;
{$IFDEF UNICODE}

function TQWorkers.LongtimeJob(AProc: TQJobProcA; AData: Pointer;
  AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr;
var
  AJob: PQJob;
begin
  if AtomicIncrement(FLongTimeWorkers) <= FMaxLongtimeWorkers then
  begin
    AJob := JobPool.Pop;
    JobInitialize(AJob, AData, AFreeType, True, false);
    AJob.SetFlags(JOB_LONGTIME, True);
    AJob.WorkerProc.Method := MakeJobProc(AProc);
    Result := Post(AJob);
  end
  else
  begin
    AtomicDecrement(FLongTimeWorkers);
    Result := 0;
  end;
end;
{$ENDIF}

function TQWorkers.LongtimeJob(AProc: TQJobProcG; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := LongtimeJob(TQJobProc(MakeJobProc(AProc)), AData, AFreeType);
end;

function TQWorkers.LookupIdleWorker(AFromStatic: Boolean): Boolean;
var
  AWorker: TQWorker;
  I: Integer;
  APendingCount, APasscount: Integer;
  procedure InternalLookupWorker;
  begin
    FLocker.Enter;
    try
      I := 0;
      while I < FWorkerCount do
      begin
        if (FWorkers[I].IsIdle) and (FWorkers[I].IsRunning) and
          (not FWorkers[I].IsFiring) then
        begin
          if AWorker = nil then
          begin
            if not FWorkers[I].FPending then
            begin
              AWorker := FWorkers[I];
              AWorker.FPending := True;
              AWorker.FEvent.SetEvent;
              Break;
            end
            else
              Inc(APendingCount);
          end;
        end;
        Inc(I);
      end;
      if FWorkerCount = MaxWorkers then // 如果已经到最大工作者，就不必重试了
        APasscount := -1
      else if (AWorker = nil) and (APendingCount = 0) then
      // 未找到且没有启动中的工作者，则尝试创建新的
      begin
        // OutputDebugString(PChar(Format('Pending %d,Passcount %d',
        // [APendingCount, APasscount])));
        AWorker := CreateWorker(false);
      end;
    finally
      FLocker.Leave;
    end;
  end;

begin
  Result := false;
  if FBusyCount >= FMaxWorkers then
    Exit
  else if (FDisableCount <> 0) or FTerminating then
    Exit;
  AWorker := nil;
  APasscount := 0;
  repeat
    APendingCount := 0;
    // 如果有正在解雇的工作者，那么等待完成
    while FFiringWorkerCount > 0 do
      ThreadYield;
    InternalLookupWorker;
    if (AWorker = nil) and (APendingCount > 0) then
    begin
      // 如果没能分配工作者并且有未启动完成的工作者，则切换掉线程的时间片，然后再尝试检查
      ThreadYield;
      Inc(APasscount);
    end;
  until (APasscount < 0) or (AWorker <> nil);
  Result := AWorker <> nil;
end;

procedure TQWorkers.NewWorkerNeeded;
begin
  TStaticThread(FStaticThread).CheckNeeded;
end;

function TQWorkers.PeekJobState(AHandle: IntPtr;
  var AResult: TQJobState): Boolean;
var
  AJob: PQJob;
  AJobHandle: IntPtr;
  ARunnings: array of IntPtr;
  procedure PeekSimpleJob(ASimpleJobs: TQSimpleJobs);
  var
    AFirst: PQJob;
  begin
    AFirst := ASimpleJobs.PopAll;
    AJob := AFirst;
    while AJob <> nil do
    begin
      if IntPtr(AJob) = AJobHandle then
      begin
        AResult.Handle := IntPtr(AJob);
        AResult.Proc := AJob.WorkerProc;
{$IFDEF UNICODE}
        if AJob.IsAnonWorkerProc then
        begin
          AResult.Proc.ProcA := nil;
          TQJobProcA(AResult.Proc.ProcA) := TQJobProcA(AJob.WorkerProc.ProcA)
        end;
{$ENDIF}
        AResult.Flags := AJob.Flags;
        AResult.PushTime := AJob.PushTime;
        if AJob.IsByPlan then
        begin
          AResult.Runs := AJob.Runs;
          AResult.PushTime := AJob.PushTime;
          AResult.PopTime := AJob.PopTime;
          AResult.AvgTime := AJob.AvgTime;
          AResult.TotalTime := AJob.TotalUsedTime;
          AResult.MaxTime := AJob.MaxUsedTime;
          AResult.MinTime := AJob.MinUsedTime;
          AResult.NextTime := GetTimestamp + MilliSecondsBetween
            (AJob.ExtData.AsPlan.Plan.NextTime, Now) * 10;
        end;
        Result := True;
        Break;
      end;
      AJob := AJob.Next;
    end;
    ASimpleJobs.Repush(AFirst);
  end;
  procedure PeekRepeatJob;
  var
    ANode: TQRBNode;
  begin
    AHandle := AHandle and (not $03);
    FRepeatJobs.FLocker.Enter;
    try
      ANode := FRepeatJobs.FItems.First;
      while ANode <> nil do
      begin
        AJob := ANode.Data;
        while Assigned(AJob) do
        begin
          if IntPtr(AJob) = AJobHandle then
          begin
            AResult.Handle := IntPtr(AJob) or $01;
            AResult.Proc := AJob.WorkerProc;
{$IFDEF UNICODE}
            if AJob.IsAnonWorkerProc then
            begin
              AResult.Proc.ProcA := nil;
              TQJobProcA(AResult.Proc.ProcA) :=
                TQJobProcA(AJob.WorkerProc.ProcA)
            end;
{$ENDIF}
            AResult.Flags := AJob.Flags;
            AResult.Runs := AJob.Runs;
            AResult.PushTime := AJob.PushTime;
            AResult.PopTime := AJob.PopTime;
            AResult.AvgTime := AJob.AvgTime;
            AResult.TotalTime := AJob.TotalUsedTime;
            AResult.MaxTime := AJob.MaxUsedTime;
            AResult.MinTime := AJob.MinUsedTime;
            AResult.NextTime := AJob.NextTime;
            Result := True;
            Exit;
          end;
          AJob := AJob.Next;
        end;
        ANode := ANode.Next;
      end;
    finally
      FRepeatJobs.FLocker.Leave;
    end;
  end;
  procedure PeekSignalJob;
  var
    ATemp: TQJobStateArray;
    ASignal: PQSignal;
    I: Integer;
  begin
    I := 0;
    AHandle := AHandle and (not $03);
    FLocker.Enter;
    try
      SetLength(ATemp, 4096);
      while I < FMaxSignalId do
      begin
        ASignal := FSignalJobs[I];

        AJob := ASignal.First;
        while Assigned(AJob) do
        begin
          if IntPtr(AJob) = AJobHandle then
          begin
            AResult.Handle := AJob.Handle;
            AResult.Proc := AJob.WorkerProc;
{$IFDEF UNICODE}
            if AJob.IsAnonWorkerProc then
            begin
              AResult.Proc.ProcA := nil;
              TQJobProcA(AResult.Proc.ProcA) :=
                TQJobProcA(AJob.WorkerProc.ProcA);
            end;
{$ENDIF}
            AResult.Runs := AJob.Runs;
            AResult.Flags := AJob.Flags;
            AResult.PushTime := AJob.PushTime;
            AResult.PopTime := AJob.PopTime;
            AResult.AvgTime := AJob.AvgTime;
            AResult.TotalTime := AJob.TotalUsedTime;
            AResult.MaxTime := AJob.MaxUsedTime;
            AResult.MinTime := AJob.MinUsedTime;
            AResult.NextTime := AJob.NextTime;
            Result := True;
            Exit;
          end;
          AJob := AJob.Next;
        end;
        Inc(I);
      end;
    finally
      FLocker.Leave;
    end;
  end;
  procedure CheckRunnings;
  var
    I: Integer;
  begin
    DisableWorkers;
    FLocker.Enter;
    try
      SetLength(ARunnings, FWorkerCount);
      I := 0;
      while I < FWorkerCount do
      begin
        if FWorkers[I].IsExecuting then
        begin
          AJob := FWorkers[I].FActiveJob;
          if IntPtr(AJob) = AJobHandle then
          begin
            if not Result then
            begin
              AResult.Handle := AHandle;
              AResult.Proc := AJob.WorkerProc;
{$IFDEF UNICODE}
              if AJob.IsAnonWorkerProc then
              begin
                AResult.Proc.ProcA := nil;
                TQJobProcA(AResult.Proc.ProcA) :=
                  TQJobProcA(AJob.WorkerProc.ProcA)
              end;
{$ENDIF}
              AResult.Runs := AJob.Runs;
              AResult.Flags := AJob.Flags;
              AResult.PushTime := AJob.PushTime;
              AResult.PopTime := AJob.PopTime;
              AResult.AvgTime := AJob.AvgTime;
              AResult.TotalTime := AJob.TotalUsedTime;
              AResult.MaxTime := AJob.MaxUsedTime;
              AResult.MinTime := AJob.MinUsedTime;
              AResult.NextTime := AJob.NextTime;
            end;
            AResult.IsRunning := True;
            Result := True;
            Exit;
          end;
        end;
        Inc(I);
      end;
    finally
      FLocker.Leave;
      EnableWorkers;
    end;
  end;

  function JobType: Integer;
  begin
    Result := AHandle and $03;
    AJobHandle := AHandle - Result;
  end;

begin
  Result := false;
  case JobType of
    0:
      PeekSimpleJob(FSimpleJobs);
    1:
      PeekRepeatJob;
    2:
      PeekSignalJob;
    3:
      PeekSimpleJob(FPlanJobs);
  end;
  CheckRunnings;
end;

function TQWorkers.Plan(AProc: TQJobProcG; const APlan: QStringW;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Plan(AProc, TQPlanMask.Create(APlan), AData, ARunInMainThread,
    AFreeType);
end;

function TQWorkers.Plan(AProc: TQJobProcG; const APlan: TQPlanMask;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Plan(TQJobProc(MakeJobProc(AProc)), APlan, AData, ARunInMainThread, AFreeType);
end;

function TQWorkers.Plan(AProc: TQJobProc; const APlan: TQPlanMask;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, TQJobExtData.Create(APlan, AData, AFreeType),
    jdfFreeAsObject, false, ARunInMainThread);
  AJob.IsByPlan := True;
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  Result := Post(AJob);
end;

function TQWorkers.Plan(AProc: TQJobProc; const APlan: QStringW; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Plan(AProc, TQPlanMask.Create(APlan), AData, ARunInMainThread,
    AFreeType);
end;

{$IFDEF UNICODE}

function TQWorkers.Plan(AProc: TQJobProcA; const APlan: TQPlanMask;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, TQJobExtData.Create(APlan, AData, AFreeType),
    jdfFreeAsObject, false, ARunInMainThread);
  AJob.IsByPlan := True;
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  Result := Post(AJob);
end;

function TQWorkers.Plan(AProc: TQJobProcA; const APlan: QStringW;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Plan(AProc, TQPlanMask.Create(APlan), AData, ARunInMainThread,
    AFreeType);
end;

{$ENDIF}

procedure TQWorkers.PlanCheckNeeded;
var
  H, M, S, MS: Word;
begin
  if FPlanCheckJob = 0 then
  begin
    FLocker.Enter;
    try
      if FPlanCheckJob = 0 then // 再次检查，以避免在判断和锁定进入之前，别的线程已经执行过此段代码
      begin
        DecodeTime(Now, H, M, S, MS);
        // 修改延迟，以便尽量精确到秒的0点
        FPlanCheckJob := At(DoPlanCheck, (1000 - MS) * Q1MillSecond, Q1Second,
          nil, false);
      end;
    finally
      FLocker.Leave;
    end;
  end;
end;

function TQWorkers.Popup: PQJob;
begin
  Result := FSimpleJobs.Pop;
  if Result = nil then
    Result := FRepeatJobs.Pop;
  if Assigned(Result) and Assigned(FBeforeExecute) then
    FBeforeExecute(Result);
end;

function TQWorkers.RegisterSignal(const AName: QStringW): Integer;
var
  ASignal: PQSignal;
  AIdx: Integer;
begin
  FLocker.Enter;
  try
    if FindSignal(AName, AIdx) then
      Result := PQSignal(FSignalNameList[AIdx]).Id
    else
    begin
      if Length(FSignalJobs) = FMaxSignalId then
        SetLength(FSignalJobs, FMaxSignalId shl 1);
      New(ASignal);
      FSignalJobs[FMaxSignalId] := ASignal;
      Inc(FMaxSignalId);
      ASignal.Id := FMaxSignalId;
      ASignal.Fired := 0;
      ASignal.Name := AName;
      ASignal.First := nil;
      Result := ASignal.Id;
      FSignalNameList.Insert(AIdx, ASignal);
      // OutputDebugString(PWideChar('Signal '+IntToStr(ASignal.Id)+' Allocate '+IntToHex(NativeInt(ASignal),8)));
    end;
  finally
    FLocker.Leave;
  end;
end;

function TQWorkers.SendSignal(AId: Integer; AData: Pointer;
  AFreeType: TQJobDataFreeType; AWaitTimeout: Cardinal): TWaitResult;
begin
  Result := SignalQueue.Send(AId, AData, AFreeType, AWaitTimeout);
end;

function TQWorkers.SendSignal(const AName: QStringW; AData: Pointer;
  AFreeType: TQJobDataFreeType; AWaitTimeout: Cardinal): TWaitResult;
begin
  Result := SignalQueue.Send(AName, AData, AFreeType, AWaitTimeout);
end;

procedure TQWorkers.SetEnabled(const Value: Boolean);
begin
  if Value then
    EnableWorkers
  else
    DisableWorkers;
end;

procedure TQWorkers.SetFireTimeout(const Value: Cardinal);
begin
  if Value = 0 then
    FFireTimeout := MaxInt
  else
    FFireTimeout := Value;
end;

procedure TQWorkers.SetMaxLongtimeWorkers(const Value: Integer);
begin
  if FMaxLongtimeWorkers <> Value then
  begin
    if Value > (MaxWorkers shr 1) then
      raise Exception.Create(STooManyLongtimeWorker);
    FMaxLongtimeWorkers := Value;
  end;
end;

procedure TQWorkers.SetMaxWorkers(const Value: Integer);
var
  ATemp, AMaxLong: Integer;
begin
  if Value < FMinWorkers then
    raise Exception.Create(SMaxMinWorkersError);
  if (Value >= 2) and (FMaxWorkers <> Value) then
  begin
    AtomicExchange(ATemp, FLongTimeWorkers);
    AtomicExchange(FMaxLongtimeWorkers, 0); // 强制置0，防止有新入的长时间作业
    AMaxLong := Value shr 1;
    FLocker.Enter;
    try
      if Value < FMinWorkers then
        FMinWorkers := Value;
      if FLongTimeWorkers < AMaxLong then // 已经进行的长时间作业数小于一半的工作者
      begin
        if (ATemp > 0) and (ATemp < AMaxLong) then
          AMaxLong := ATemp;
        if FMaxWorkers > Value then
        begin
          FMaxWorkers := Value;
          SetLength(FWorkers, Value + 1);
        end
        else
        begin
          FMaxWorkers := Value;
          SetLength(FWorkers, Value + 1);
        end;
      end;
    finally
      FLocker.Leave;
      AtomicExchange(FMaxLongtimeWorkers, AMaxLong);
    end;
  end;
end;

procedure TQWorkers.SetMinWorkers(const Value: Integer);
begin
  if FMinWorkers <> Value then
  begin
    if (Value < 1) then
      raise Exception.Create(STooFewWorkers)
    else if Value > FMaxWorkers then
      raise Exception.Create(SMaxMinWorkersError);
    FMinWorkers := Value;
  end;
end;

function TQWorkers.Signal(AId: Integer; AData: Pointer;
  AFreeType: TQJobDataFreeType; AWaitTimeout: Cardinal): TWaitResult;
begin
  Result := SignalQueue.Send(AId, AData, AFreeType, AWaitTimeout);
end;

function TQWorkers.Signal(const AName: QStringW; AData: Pointer;
  AFreeType: TQJobDataFreeType; AWaitTimeout: Cardinal): TWaitResult;
begin
  Result := SignalQueue.Send(AName, AData, AFreeType, AWaitTimeout);
end;

procedure TQWorkers.SignalWorkDone(AJob: PQJob; AUsedTime: Int64);
var
  ASignal: PQSignal;
  ATemp, APrior: PQJob;
begin
  FLocker.Enter;
  try
    ASignal := FSignalJobs[PQSignalQueueItem(AJob.SignalData).Id - 1];
    ATemp := ASignal.First;
    APrior := nil;
    while ATemp <> nil do
    begin
      if ATemp = AJob.Source then
      begin
        if AJob.IsTerminated then
        begin
          if APrior <> nil then
            APrior.Next := ATemp.Next
          else
            ASignal.First := ATemp.Next;
          ATemp.Next := nil;
          FreeJob(ATemp);
        end
        else
        begin
          // 更新信号作业的统计信息
          Inc(ATemp.Runs);
          if AUsedTime > 0 then
          begin
            if ATemp.MinUsedTime = 0 then
              ATemp.MinUsedTime := AUsedTime
            else if AUsedTime < ATemp.MinUsedTime then
              ATemp.MinUsedTime := AUsedTime;
            if ATemp.MaxUsedTime = 0 then
              ATemp.MaxUsedTime := AUsedTime
            else if AUsedTime > ATemp.MaxUsedTime then
              ATemp.MaxUsedTime := AUsedTime;
            Break;
          end;
        end;
      end;
      APrior := ATemp;
      ATemp := ATemp.Next;
    end;
  finally
    FLocker.Leave;
  end;
end;

procedure TQWorkers.ValidWorkers;
{$IFDEF VALID_WORKERS}
var
  I: Integer;
{$ENDIF}
begin
{$IFDEF VALID_WORKERS}
  for I := 0 to FWorkerCount - 1 do
  begin
    if FWorkers[I] = nil then
      OutputDebugString('Workers array bad')
    else if FWorkers[I].FIndex <> I then
      OutputDebugString('Workers index bad');
  end;
{$ENDIF}
end;

procedure TQWorkers.WorkerTimeout(AWorker: TQWorker);
var
  AWorkers: Integer;
begin
  AWorkers := FWorkerCount - AtomicIncrement(FFiringWorkerCount);
  if (AWorkers < FMinWorkers) or (AWorkers = BusyWorkers) then // 至超过1个空闲
    AtomicDecrement(FFiringWorkerCount)
  else
  begin
    AWorker.SetFlags(WORKER_FIRING, True);
    AWorker.Terminate;
  end;
end;

procedure TQWorkers.WorkerTerminate(AWorker: TQWorker);
var
  I, J: Integer;
begin
  FLocker.Enter;
  try
    Dec(FWorkerCount);
    if AWorker.IsFiring then
      AtomicDecrement(FFiringWorkerCount);
    // 如果是当前忙碌的工作者被解雇
    if FWorkerCount = 0 then
    begin
      FWorkers[0] := nil;
      if Assigned(FTerminateEvent) then
        FTerminateEvent.SetEvent;
    end
    else
    begin
      for I := 0 to FWorkerCount do
      begin
        if AWorker = FWorkers[I] then
        begin
          for J := I to FWorkerCount do
            FWorkers[J] := FWorkers[J + 1];
          Break;
        end;
      end;
    end;
  finally
    FLocker.Leave;
  end;
end;

function TQWorkers.Wait(AProc: TQJobProc; ASignalId: Integer;
  ARunInMainThread: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
  ASignal: PQSignal;
begin
  if (not FTerminating) and Assigned(AProc) then
  begin
    AJob := JobPool.Pop;
    JobInitialize(AJob, AData, AFreeType, false, ARunInMainThread);
{$IFDEF NEXTGEN}
    PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
    AJob.WorkerProc.Proc := AProc;
{$ENDIF}
    // Assert(AJob.WorkerProc.Code<>nil);
    AJob.SetFlags(JOB_SIGNAL_WAKEUP, True);
    AJob.PushTime := GetTimestamp;
    Result := 0;
    FLocker.Enter;
    try
      if (ASignalId >= 1) and (ASignalId <= FMaxSignalId) then
      begin
        ASignal := FSignalJobs[ASignalId - 1];
        AJob.Next := ASignal.First;
        ASignal.First := AJob;
        Result := AJob.Handle;
      end;
    finally
      FLocker.Leave;
      if Result = 0 then
        JobPool.Push(AJob);
    end;
  end
  else
    Result := 0;
end;

function TQWorkers.Wait(AProc: TQJobProc; const ASignalName: QStringW;
  ARunInMainThread: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Wait(AProc, RegisterSignal(ASignalName), ARunInMainThread, AData,
    AFreeType);
end;

{$IFDEF UNICODE}

function TQWorkers.Wait(AProc: TQJobProcA; ASignalId: Integer;
  ARunInMainThread: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
  ASignal: PQSignal;
begin
  if (not FTerminating) and Assigned(AProc) then
  begin
    AJob := JobPool.Pop;
    JobInitialize(AJob, AData, AFreeType, false, ARunInMainThread);
    AJob.WorkerProc.Method := MakeJobProc(AProc);
    AJob.SetFlags(JOB_SIGNAL_WAKEUP, True);
    AJob.PushTime := GetTimestamp;
    Result := 0;
    FLocker.Enter;
    try
      if (ASignalId >= 1) and (ASignalId <= FMaxSignalId) then
      begin
        ASignal := FSignalJobs[ASignalId - 1];
        AJob.Next := ASignal.First;
        ASignal.First := AJob;
        Result := AJob.Handle;
      end;
    finally
      FLocker.Leave;
      if Result = 0 then
        JobPool.Push(AJob);
    end;
  end
  else
    Result := 0;
end;

function TQWorkers.Wait(AProc: TQJobProcA; const ASignalName: QStringW;
  ARunInMainThread: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Wait(AProc, RegisterSignal(ASignalName), ARunInMainThread, AData,
    AFreeType);
end;

{$ENDIF}

function TQWorkers.WaitJob(AHandle: IntPtr; ATimeout: Cardinal;
  AMsgWait: Boolean): TWaitResult;
var
  AFirst, AJob: PQJob;
  AChain: PQJobWaitChain;
  I: Integer;
  procedure AddWait;
  begin
    New(AChain);
    AChain.Event := TEvent.Create(nil, false, false, '');
    AChain.Job := AHandle;
    AChain.Prior := nil;
    FLocker.Enter;
    AChain.Prior := FLastWaitChain;
    FLastWaitChain := AChain;
    FLocker.Leave;
  end;
  procedure RemoveWait;
  var
    APrior, ANext: PQJobWaitChain;
  begin
    if Assigned(AChain) then
    begin
      ANext := nil;
      FLocker.Enter;
      try
        APrior := FLastWaitChain;
        while Assigned(APrior) do
        begin
          if APrior = AChain then
          begin
            if Assigned(ANext) then
              ANext.Prior := APrior.Prior
            else
              FLastWaitChain := APrior.Prior;
            Break;
          end;
          ANext := APrior;
          APrior := APrior.Prior;
        end;
      finally
        FLocker.Leave;
        FreeAndNil(AChain.Event);
        Dispose(AChain);
      end;
    end;
  end;

  procedure AbortWaits;
  var
    APrior: PQJobWaitChain;
  begin
    FLocker.Enter;
    try
      APrior := FLastWaitChain;
      while Assigned(APrior) do
      begin
        if APrior <> AChain then
          TEvent(APrior.Event).SetEvent;
        APrior := APrior.Prior;
      end;
    finally
      FLocker.Leave;
    end;
  end;

begin
  if (AHandle and $3) = 0 then
  begin
    AChain := nil;
    try
      AFirst := FSimpleJobs.PopAll;
      try
        AJob := AFirst;
        while AJob <> nil do
        begin
          if AHandle = IntPtr(AJob) then
          begin
            AddWait;
            Break;
          end
          else
            AJob := AJob.Next;
        end;
      finally
        FSimpleJobs.Repush(AFirst);
        LookupIdleWorker(false);
      end;
      if not Assigned(AChain) then
      begin
        FLocker.Enter;
        try
          for I := 0 to FWorkerCount - 1 do
          begin
            if IntPtr(FWorkers[I].FActiveJob) = AHandle then
            begin
              AddWait;
              Break;
            end;
          end;
        finally
          FLocker.Leave;
        end;
      end;
      if Assigned(AChain) then
      begin
        if AMsgWait then
        begin
          Result := MsgWaitForEvent(AChain.Event, ATimeout);
          if (Result = wrAbandoned) and AppTerminated then
            AbortWaits;
        end
        else
        begin
          if Terminating then
            Result := wrAbandoned
          else
            Result := TEvent(AChain.Event).WaitFor(ATimeout);
        end;
      end
      else
        Result := wrSignaled;
    finally
      RemoveWait;
    end;
  end
  else
    Result := wrError;
end;

function TQWorkers.Wait(AProc: TQJobProcG; ASignalId: Integer;
  ARunInMainThread: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Wait(TQJobProc(MakeJobProc(AProc)), ASignalId, ARunInMainThread, AData,
    AFreeType);
end;

function TQWorkers.Wait(AProc: TQJobProcG; const ASignalName: QStringW;
  ARunInMainThread: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Wait(AProc, RegisterSignal(ASignalName), ARunInMainThread, AData,
    AFreeType);
end;

procedure TQWorkers.WaitRunningDone(const AParam: TWorkerWaitParam;
  AMarkTerminateOnly: Boolean);
var
  AInMainThread: Boolean;
  function HasJobRunning: Boolean;
  var
    I: Integer;
    AJob: PQJob;
    AFound: Boolean;
  begin
    Result := false;
    DisableWorkers;
    FLocker.Enter;
    try
      for I := 0 to FWorkerCount - 1 do
      begin
        if FWorkers[I].IsLookuping then // 还未就绪，所以在下次查询
        begin
          Result := True;
          Break;
        end
        else if FWorkers[I].IsExecuting then
        begin
          if not FWorkers[I].IsCleaning then
          begin
            AJob := FWorkers[I].FActiveJob;
            case AParam.WaitType of
              0: // ByObject
                AFound := TMethod(FWorkers[I].FActiveJobProc)
                  .Data = AParam.Bound;
              1:
                // ByData
                AFound := (TMethod(FWorkers[I].FActiveJobProc)
                  .Code = TMethod(AParam.WorkerProc).Code) and
                  (TMethod(FWorkers[I].FActiveJobProc)
                  .Data = TMethod(AParam.WorkerProc).Data) and
                  ((AParam.Data = INVALID_JOB_DATA) or
                  (FWorkers[I].FActiveJobData = AParam.Data));
              2: // BySignalSource
                AFound := (FWorkers[I].FActiveJobSource = AParam.SourceJob);
              3, 5: // ByGroup,ByPlan: Group/PlanSource是同一地址
                AFound := (FWorkers[I].FActiveJobGroup = AParam.Group);
              4: // ByJob
                AFound := (AJob = AParam.SourceJob);
              $FF: // 所有
                AFound := True;
            else
              begin
                if Assigned(FOnError) then
                  FOnError(AJob, Exception.CreateFmt(SBadWaitDoneParam,
                    [AParam.WaitType]), jesWaitDone)
                else
                  raise Exception.CreateFmt(SBadWaitDoneParam,
                    [AParam.WaitType]);
              end;
            end;
            if AFound then
            begin
              FWorkers[I].FTerminatingJob := AJob;
              // 检查是否当前是主线程中停止主线程作业，如果是的话，是无法停止的，所以只是标记一下
              if (not AMarkTerminateOnly) and AJob.InMainThread and
                (GetCurrentThreadId = MainThreadId) then
              begin
{$IFDEF DEBUG}
                raise Exception.Create(STerminateMainThreadJobInMainThread);
{$ENDIF}
                AMarkTerminateOnly := True;
              end;
              Result := True;
            end;
          end
          else
            Result := True;
        end;
      end;
    finally
      FLocker.Leave;
      EnableWorkers;
    end;
  end;

begin
  AInMainThread := GetCurrentThreadId = MainThreadId;
  repeat
    if HasJobRunning and (not AMarkTerminateOnly) then
    begin
      if AInMainThread then
        // 如果是在主线程中清理，由于作业可能在主线程执行，可能已经投寄尚未执行，所以必需让其能够执行
        ProcessAppMessage;
      Sleep(10);
    end
    else // 没找到
      Break;
  until 1 > 2;
end;

procedure TQWorkers.WaitSignalJobsDone(AJob: PQJob);
begin
  TEvent(AJob.Data).SetEvent;
end;

function TQWorkers.Clear(ASignalName: QStringW;
  AWaitRunningDone: Boolean): Integer;
var
  I: Integer;
  ASignal: PQSignal;
  AJob: PQJob;
begin
  Result := 0;
  FLocker.Enter;
  try
    AJob := nil;
    for I := 0 to FMaxSignalId - 1 do
    begin
      ASignal := FSignalJobs[I];
      if ASignal.Name = ASignalName then
      begin
        AJob := ASignal.First;
        ASignal.First := nil;
        Break;
      end;
    end;
  finally
    FLocker.Leave;
  end;
  if AJob <> nil then
    ClearSignalJobs(AJob, AWaitRunningDone);
end;
{$IFDEF UNICODE}

function TQWorkers.At(AProc: TQJobProcA; const ADelay, AInterval: Int64;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  AJob.Interval := AInterval;
  AJob.FirstDelay := ADelay;
  Result := Post(AJob);
end;
{$ENDIF}

function TQWorkers.At(AProc: TQJobProcG; const ADelay, AInterval: Int64;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := At(TQJobProc(MakeJobProc(AProc)), ADelay, AInterval, AData, ARunInMainThread,
    AFreeType);
end;

function TQWorkers.At(AProc: TQJobProcG; const ATime: TDateTime;
  const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := At(TQJobProc(MakeJobProc(AProc)), ATime, AInterval, AData, ARunInMainThread,
    AFreeType);
end;

procedure TQWorkers.CheckWaitChain(AJob: PQJob);
  procedure NotifyIfWaiting;
  var
    AChain, APrior, ANext: PQJobWaitChain;
  begin
    AChain := FLastWaitChain;
    ANext := nil;
    while Assigned(AChain) do
    begin
      APrior := AChain.Prior;
      if AChain.Job = IntPtr(AJob) then
      begin
        if Assigned(ANext) then
          ANext.Prior := AChain.Prior
        else
          FLastWaitChain := AChain.Prior;
        TEvent(AChain.Event).SetEvent;
      end;
      AChain := APrior;
    end;
  end;

begin
  if Assigned(FLastWaitChain) then
  begin
    FLocker.Enter;
    try
      while Assigned(AJob) and Assigned(FLastWaitChain) do
      begin
        NotifyIfWaiting;
        AJob := AJob.Next;
      end;
    finally
      FLocker.Leave;
    end;
  end;
end;

function TQWorkers.Clear(ASignalId: Integer; AWaitRunningDone: Boolean)
  : Integer;
var
  AJob: PQJob;
begin
  FLocker.Enter;
  try
    if (ASignalId >= 1) and (ASignalId <= FMaxSignalId) then
    begin
      with FSignalJobs[ASignalId - 1]^ do
      begin
        AJob := First;
        First := nil;
      end;
    end
    else
      AJob := nil;
  finally
    FLocker.Leave;
  end;
  if AJob <> nil then
    Result := ClearSignalJobs(AJob, AWaitRunningDone)
  else
    Result := 0;
end;
{$IFDEF UNICODE}

function TQWorkers.Clear(AProc: TQJobProcA; AData: Pointer; AMaxTimes: Integer;
  AWaitRunningDone: Boolean): Integer;
begin

end;
{$ENDIF}

function TQWorkers.Clear(AProc: TQJobProcG; AData: Pointer; AMaxTimes: Integer;
  AWaitRunningDone: Boolean): Integer;
begin
  Result := Clear(TQJobProc(MakeJobProc(AProc)), AData, AMaxTimes, AWaitRunningDone);
end;

procedure TQWorkers.Clear(AWaitRunningDone: Boolean);
var
  I: Integer;
  AParam: TWorkerWaitParam;
  ASignal: PQSignal;
begin
  DisableWorkers; // 避免工作者取得新的作业
  try
    FSimpleJobs.Clear;
    FRepeatJobs.Clear;
    FPlanJobs.Clear;
    FLocker.Enter;
    try
      for I := 0 to FMaxSignalId - 1 do
      begin
        ASignal := FSignalJobs[I];
        FreeJob(ASignal.First);
        ASignal.First := nil;
      end;
    finally
      FLocker.Leave;
    end;
    AParam.WaitType := $FF;
    WaitRunningDone(AParam);
    FPlanCheckJob := 0;
  finally
    EnableWorkers;
  end;
end;

function TQWorkers.ClearSignalJobs(ASource: PQJob;
  AWaitRunningDone: Boolean): Integer;
var
  AFirst, ALast, APrior, ANext: PQJob;
  ACount: Integer;
  AWaitParam: TWorkerWaitParam;
begin
  Result := 0;
  AFirst := nil;
  APrior := nil;
  FSimpleJobs.FLocker.Enter;
  try
    ALast := FSimpleJobs.FFirst;
    ACount := FSimpleJobs.Count;
    FSimpleJobs.FFirst := nil;
    FSimpleJobs.FLast := nil;
    FSimpleJobs.FCount := 0;
  finally
    FSimpleJobs.FLocker.Leave;
  end;
  while ALast <> nil do
  begin
    if (ALast.IsSignalWakeup) and (ALast.Source = ASource) then
    begin
      ANext := ALast.Next;
      ALast.Next := nil;
      FreeJob(ALast);
      ALast := ANext;
      if APrior <> nil then
        APrior.Next := ANext;
      Dec(ACount);
      Inc(Result);
    end
    else
    begin
      if AFirst = nil then
        AFirst := ALast;
      APrior := ALast;
      ALast := ALast.Next;
    end;
  end;
  if ACount > 0 then
  begin
    FSimpleJobs.FLocker.Enter;
    try
      APrior.Next := FSimpleJobs.FFirst;
      FSimpleJobs.FFirst := AFirst;
      Inc(FSimpleJobs.FCount, ACount);
      if FSimpleJobs.FLast = nil then
        FSimpleJobs.FLast := APrior;
    finally
      FSimpleJobs.FLocker.Leave;
    end;
  end;
  AWaitParam.WaitType := 2;
  AWaitParam.SourceJob := ASource;
  WaitRunningDone(AWaitParam, not AWaitRunningDone);
  FreeJob(ASource);
end;
{$IFDEF UNICODE}

function TQWorkers.Post(AProc: TQJobProcA; AInterval: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  AJob.Interval := AInterval;
  Result := Post(AJob);
end;

{$ENDIF}

function TQWorkers.PostSignal(AId: Integer; AData: Pointer;
  AFreeType: TQJobDataFreeType): Boolean;
begin
  Result := SignalQueue.Post(AId, AData, AFreeType);
end;

function TQWorkers.PostSignal(const AName: QStringW; AData: Pointer;
  AFreeType: TQJobDataFreeType): Boolean;
begin
  Result := SignalQueue.Post(AName, AData, AFreeType);
end;

function TQWorkers.Post(AProc: TQJobProcG; AInterval: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
begin
  Result := Post(TQJobProc(MakeJobProc(AProc)), AInterval, AData, ARunInMainThread,
    AFreeType);
end;

procedure TQWorkers.ClearSingleJob(AHandle: IntPtr; AWaitRunningDone: Boolean);
var
  AInstance: PQJob;
  AWaitParam: TWorkerWaitParam;

  function RemoveSignalJob: PQJob;
  var
    I: Integer;
    AJob, ANext, APrior: PQJob;
    ASignal: PQSignal;
  begin
    Result := nil;
    FLocker.Enter;
    try
      for I := 0 to FMaxSignalId - 1 do
      begin
        ASignal := FSignalJobs[I];
        AJob := ASignal.First;
        APrior := nil;
        while Assigned(AJob) do
        begin
          ANext := AJob.Next;
          if AJob = AInstance then
          begin
            if ASignal.First = AJob then
              ASignal.First := ANext;
            if Assigned(APrior) then
              APrior.Next := ANext;
            AJob.Next := nil;
            Result := AJob;
            Exit;
          end
          else
            APrior := AJob;
          AJob := ANext;
        end;
      end;
    finally
      FLocker.Leave;
    end;
  end;
  function ClearSignalJob: Boolean;
  var
    AJob: PQJob;
  begin
    AJob := RemoveSignalJob;
    if Assigned(AJob) then
      ClearSignalJobs(AJob, AWaitRunningDone);
    Result := AJob <> nil;
  end;

begin
  AInstance := HandleToJob(AHandle);
  FillChar(AWaitParam, SizeOf(TWorkerWaitParam), 0);
  AWaitParam.SourceJob := AInstance;
  case AHandle and $03 of
    0:
      // SimpleJobs
      begin
        if FSimpleJobs.Clear(AHandle) then // 简单作业要么在队列中，要么不在
          Exit;
        AWaitParam.WaitType := 4;
      end;
    1: // RepeatJobs
      begin
        if not FRepeatJobs.Clear(IntPtr(AInstance)) then // 重复队列如果不在队列中，说明已经被清除了
          Exit;
        AWaitParam.WaitType := 2;
      end;
    2: // SignalJobs;
      begin
        if ClearSignalJob then
          Exit;
        AWaitParam.WaitType := 2;
      end;
    3: // 计划任务
      begin
        FPlanJobs.Clear(IntPtr(AInstance));
        // 计划任务要么在队列中，要么在执行中
        AWaitParam.WaitType := 5;
      end;
  end;
  WaitRunningDone(AWaitParam, not AWaitRunningDone);
end;

function TQWorkers.ClearJobs(AHandles: PIntPtr; ACount: Integer;
  AWaitRunningDone: Boolean): Integer;
var
  ASimpleHandles: array of IntPtr;
  APlanHandles: array of IntPtr;
  ARepeatHandles: array of IntPtr;
  ASignalHandles: array of IntPtr;
  ASimpleCount, ARepeatCount, ASignalCount, APlanCount: Integer;
  I: Integer;
  AWaitParam: TWorkerWaitParam;

  function SignalJobCanRemove(AHandle: IntPtr): Boolean;
  var
    T: Integer;
  begin
    Result := false;
    for T := 0 to ASignalCount - 1 do
    begin
      if ASignalHandles[T] = AHandle then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;

  function ClearSignals: Integer;
  var
    I: Integer;
    AJob, ANext, APrior, AFirst: PQJob;
    ASignal: PQSignal;
  begin
    Result := 0;
    AFirst := nil;
    FLocker.Enter;
    try
      for I := 0 to FMaxSignalId - 1 do
      begin
        ASignal := FSignalJobs[I];
        AJob := ASignal.First;
        APrior := nil;
        while AJob <> nil do
        begin
          ANext := AJob.Next;
          if SignalJobCanRemove(IntPtr(AJob)) then
          begin
            if ASignal.First = AJob then
              ASignal.First := ANext;
            if Assigned(APrior) then
              APrior.Next := ANext;
            AJob.Next := nil;
            if Assigned(AFirst) then
              AJob.Next := AFirst;
            AFirst := AJob;
          end
          else
            APrior := AJob;
          AJob := ANext;
          Inc(Result);
        end;
      end;
    finally
      FLocker.Leave;
    end;
    while AFirst <> nil do
    begin
      ANext := AFirst.Next;
      AFirst.Next := nil;
      ClearSignalJobs(AFirst);
      AFirst := ANext;
    end;
  end;

begin
  Result := 0;
  SetLength(ASimpleHandles, ACount);
  SetLength(ARepeatHandles, ACount);
  SetLength(ASignalHandles, ACount);
  SetLength(APlanHandles, ACount);
  ASimpleCount := 0;
  ARepeatCount := 0;
  ASignalCount := 0;
  APlanCount := 0;
  I := 0;
  while I < ACount do
  begin
    case (IntPtr(AHandles^) and $03) of
      0:
        // Simple Jobs
        begin
          ASimpleHandles[ASimpleCount] := (IntPtr(AHandles^) and (not $03));
          Inc(ASimpleCount);
        end;
      1: // RepeatJobs
        begin
          ARepeatHandles[ARepeatCount] := (IntPtr(AHandles^) and (not $03));
          Inc(ARepeatCount);
        end;
      2: // SignalJobs
        begin
          ASignalHandles[ASignalCount] := (IntPtr(AHandles^) and (not $03));
          Inc(ASignalCount);
        end;
      3: // Plan job
        begin
          APlanHandles[APlanCount] := IntPtr(HandleToJob(AHandles^));
          Inc(APlanCount);
        end;
    end;
    Inc(I);
  end;
  if APlanCount > 0 then
    Inc(Result, FPlanJobs.Clear(@APlanHandles[0], APlanCount));
  if ASimpleCount > 0 then
    Inc(Result, FSimpleJobs.Clear(@ASimpleHandles[0], ASimpleCount));
  if ARepeatCount > 0 then
    Inc(Result, FRepeatJobs.Clear(@ARepeatHandles[0], ARepeatCount));
  if ASignalCount > 0 then
    Inc(Result, ClearSignals);
  if AWaitRunningDone then
  begin
    FillChar(AWaitParam, SizeOf(TWorkerWaitParam), 0);
    I := 0;
    while I < ASimpleCount do
    begin
      if ASimpleHandles[I] <> 0 then
      begin
        AWaitParam.SourceJob := Pointer(ASimpleHandles[I]);
        AWaitParam.WaitType := 4;
        WaitRunningDone(AWaitParam);
        Inc(Result);
      end;
      Inc(I);
    end;
    I := 0;
    while I < ASimpleCount do
    begin
      if ASimpleHandles[I] <> 0 then
      begin
        AWaitParam.SourceJob := Pointer(APlanHandles[I]);
        AWaitParam.WaitType := 5;
        WaitRunningDone(AWaitParam);
        Inc(Result);
      end;
      Inc(I);
    end;
    I := 0;
    while I < ARepeatCount do
    begin
      if ARepeatHandles[I] <> 0 then
      begin
        AWaitParam.SourceJob := Pointer(ARepeatHandles[I]);
        AWaitParam.WaitType := 2;
        WaitRunningDone(AWaitParam);
        Inc(Result);
      end;
    end;
  end;
end;

{ TJobPool }

constructor TJobPool.Create(AMaxSize: Integer);
begin
  inherited Create;
  FSize := AMaxSize;
  FLocker := TQSimpleLock.Create;
end;

destructor TJobPool.Destroy;
var
  AJob: PQJob;
begin
  FLocker.Enter;
  while FFirst <> nil do
  begin
    AJob := FFirst.Next;
    Dispose(FFirst);
    FFirst := AJob;
  end;
  FreeObject(FLocker);
  inherited;
end;

function TJobPool.Pop: PQJob;
begin
  FLocker.Enter;
  Result := FFirst;
  if Result <> nil then
  begin
    FFirst := Result.Next;
    Dec(FCount);
  end;
  FLocker.Leave;
  if Result = nil then
    GetMem(Result, SizeOf(TQJob));
  Result.Reset;
end;

procedure TJobPool.Push(AJob: PQJob);
var
  ADoFree: Boolean;
begin
{$IFDEF UNICODE}
  if AJob.IsAnonWorkerProc then
    TQJobProcA(AJob.WorkerProc.ProcA) := nil
  else
    PQJobProc(@AJob.WorkerProc)^ := nil;
{$ENDIF}
  FLocker.Enter;
  ADoFree := (FCount = FSize);
  if not ADoFree then
  begin
    AJob.Next := FFirst;
    FFirst := AJob;
    Inc(FCount);
  end;
  FLocker.Leave;
  if ADoFree then
  begin
    FreeMem(AJob);
  end;
end;

{ TQSimpleLock }
{$IFDEF QWORKER_SIMPLE_LOCK}

constructor TQSimpleLock.Create;
begin
  inherited;
  FFlags := 0;
end;

procedure TQSimpleLock.Enter;
begin
  while (AtomicOr(FFlags, $01) and $01) <> 0 do
  begin
    GiveupThread;
  end;
end;

procedure TQSimpleLock.Leave;
begin
  AtomicAnd(FFlags, Integer($FFFFFFFE));
end;
{$ENDIF QWORKER_SIMPLE_JOB}
{ TQJobGroup }

function TQJobGroup.Add(AProc: TQJobProc; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
  AJob := InitGroupJob(AData, AInMainThread, AFreeType);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  Result := InternalAddJob(AJob);
end;

function TQJobGroup.Add(AProc: TQJobProcG; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
begin
  Result := Add(TQJobProc(MakeJobProc(AProc)), AData, AInMainThread, AFreeType);
end;
{$IFDEF UNICODE}

function TQJobGroup.Add(AProc: TQJobProcA; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
  AJob := InitGroupJob(AData, AInMainThread, AFreeType);
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  Result := InternalAddJob(AJob);
end;
{$ENDIF}

function TQJobGroup.Add(AJob: PQJob): Boolean;
begin
  AJob.Group := Self;
  AJob.SetFlags(JOB_GROUPED, True);
  AJob.PushTime := 0;
  Result := InternalAddJob(AJob);
  if not Result then
    Workers.FreeJob(AJob);
end;

procedure TQJobGroup.Cancel(AWaitRunningDone: Boolean);
var
  I: Integer;
  AJob: PQJob;
  AWaitParam: TWorkerWaitParam;
begin
  FLocker.Enter;
  try
    AtomicExchange(FCanceled, 0);
    if FByOrder then
    begin
      I := 0;
      while I < FItems.Count do
      begin
        AJob := FItems[I];
        if AJob.PopTime = 0 then
        begin
          Workers.FreeJob(AJob);
          FItems.Delete(I);
          AtomicIncrement(FCanceled);
        end
        else
          Inc(I);
      end;
    end;
    FItems.Clear;
  finally
    FLocker.Leave;
  end;
  if FPosted <> 0 then
  begin
    I := Workers.FSimpleJobs.Clear(Self, MaxInt);
    if I > 0 then
    begin
      AtomicIncrement(FPosted, -I);
      AtomicIncrement(FCanceled, I);
    end;
    if AWaitRunningDone then
    begin
      AWaitParam.WaitType := 3;
      AWaitParam.Group := Self;
      Workers.WaitRunningDone(AWaitParam);
    end;
  end;
  if FPosted = 0 then
  begin
    if FCanceled > 0 then
      FWaitResult := wrAbandoned;
    if FWaitingCount > 0 then
      FEvent.SetEvent;
  end;
end;

constructor TQJobGroup.Create(AByOrder: Boolean);
begin
  inherited Create;
  FEvent := TEvent.Create(nil, false, false, '');
  FLocker := TQSimpleLock.Create;
  FByOrder := AByOrder;
  FItems := TQJobItemList.Create;
end;

destructor TQJobGroup.Destroy;
var
  I: Integer;
begin
  Cancel;
  if FTimeoutCheck then
    Workers.Clear(Self, 1);
  FLocker.Enter;
  try
    if FItems.Count > 0 then
    begin
      FWaitResult := wrAbandoned;
      FEvent.SetEvent;
      for I := 0 to FItems.Count - 1 do
      begin
        if PQJob(FItems[I]).PushTime <> 0 then
          JobPool.Push(FItems[I]);
      end;
      FItems.Clear;
    end;
  finally
    FLocker.Leave;
  end;
  FreeObject(FLocker);
  FreeObject(FEvent);
  FreeObject(FItems);
  inherited;
end;

procedure TQJobGroup.DoAfterDone;
begin
  try
    if Assigned(FAfterDone) then
      FAfterDone(Self);
  finally
    if FFreeAfterDone then
    begin
      FreeObject(Self);
    end;
  end;
end;

procedure TQJobGroup.DoJobExecuted(AJob: PQJob);
var
  I: Integer;
  AIsDone: Boolean;
begin
  AtomicIncrement(FRuns);
  if FWaitResult = wrIOCompletion then
  begin
    AIsDone := false;
    FLocker.Enter;
    try
      I := FItems.IndexOf(AJob);
      if I <> -1 then
      begin
        FItems.Delete(I);
        if FItems.Count = 0 then
        begin
          AIsDone := True;
          FWaitResult := wrSignaled;
          AtomicExchange(FPosted, 0);
        end
        else if ByOrder then
        begin
          if Workers.Post(FItems[0]) = 0 then
          begin
            AtomicDecrement(FPosted);
            FItems.Delete(0); // 投寄失败时，Post自动释放了作业
            FWaitResult := wrAbandoned;
            AIsDone := True;
          end
        end
        else if (FMaxWorkers > 0) and (FPosted <= FMaxWorkers) and
          (FPosted <= FItems.Count) then
        begin
          if Workers.Post(FItems[FPosted - 1]) = 0 then
          begin
            AtomicDecrement(FPosted);
            FItems.Delete(0); // 投寄失败时，Post自动释放了作业
            FWaitResult := wrAbandoned;
            AIsDone := True;
          end
        end
        else
          AtomicDecrement(FPosted);
      end
      else
      begin
        AIsDone := (FItems.Count = 0) and (AtomicDecrement(FPosted) = 0);
        if AIsDone then
        begin
          if FCanceled = 0 then
            FWaitResult := wrSignaled
          else
          begin
            FWaitResult := wrAbandoned;
            AtomicExchange(FCanceled, 0);
          end;
        end;
      end;
    finally
      FLocker.Leave;
    end;
    if AIsDone then
    begin
      FEvent.SetEvent;
      DoAfterDone;
    end;
  end;
end;

procedure TQJobGroup.DoJobsTimeout(AJob: PQJob);
begin
  FTimeoutCheck := false;
  Cancel;
  if FWaitResult = wrIOCompletion then
  begin
    FWaitResult := wrTimeout;
    FEvent.SetEvent;
    DoAfterDone;
  end;
end;

function TQJobGroup.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TQJobGroup.InitGroupJob(AData: Pointer; AInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): PQJob;
begin
  Result := JobPool.Pop;
  JobInitialize(Result, AData, AFreeType, True, AInMainThread);
  Result.Group := Self;
  Result.SetFlags(JOB_GROUPED, True);
end;

function TQJobGroup.Insert(AIndex: Integer; AProc: TQJobProc; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
  AJob := InitGroupJob(AData, AInMainThread, AFreeType);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc.Proc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  Result := InternalInsertJob(AIndex, AJob);
end;

function TQJobGroup.Insert(AIndex: Integer; AProc: TQJobProcG; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
  AJob := InitGroupJob(AData, AInMainThread, AFreeType);
  AJob.WorkerProc.ProcG := AProc;
  Result := InternalInsertJob(AIndex, AJob);
end;
{$IFDEF UNICODE}

function TQJobGroup.Insert(AIndex: Integer; AProc: TQJobProcA; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
  AJob := InitGroupJob(AData, AInMainThread, AFreeType);
  AJob.WorkerProc.Method := MakeJobProc(AProc);
  Result := InternalInsertJob(AIndex, AJob);
end;
{$ENDIF}

function TQJobGroup.InternalAddJob(AJob: PQJob): Boolean;
begin
  FLocker.Enter;
  try
    FWaitResult := wrIOCompletion;
    if (FPrepareCount > 0) or ((FMaxWorkers > 0) and (FPosted >= FMaxWorkers))
    then // 正在添加项目或者已经到达允许并发的上限，则加到列表中，等待Run或有作业完成
    begin
      FItems.Add(AJob);
      Result := True;
    end
    else
    begin
      if ByOrder then
      // 按顺序
      begin
        Result := True;
        FItems.Add(AJob);
        if FItems.Count = 1 then
          Result := Workers.Post(AJob) <> 0;
      end
      else
      begin
        Result := Workers.Post(AJob) <> 0;
        if Result then
          FItems.Add(AJob);
      end;
      if Result then
        AtomicIncrement(FPosted);
    end;
  finally
    FLocker.Leave;
  end;
end;

function TQJobGroup.InternalInsertJob(AIndex: Integer; AJob: PQJob): Boolean;
begin
  FLocker.Enter;
  try
    FWaitResult := wrIOCompletion;
    if AIndex > FItems.Count then
      AIndex := FItems.Count
    else if AIndex < 0 then
      AIndex := 0;
    if (FPrepareCount > 0) or ((FMaxWorkers > 0) and (FPosted >= FMaxWorkers))
    then // 正在添加项目或者已经到达允许并发的上限，则加到列表中，等待Run或有作业完成
    begin
      FItems.Insert(AIndex, AJob);
      Result := True;
    end
    else
    begin
      if ByOrder then // 按顺序
      begin
        Result := True;
        FItems.Insert(AIndex, AJob);
        if FItems.Count = 1 then
          Result := Workers.Post(AJob) <> 0;
      end
      else
      // 不按顺序触发时，其等价于Add
      begin
        Result := Workers.Post(AJob) <> 0;
        if Result then
          FItems.Add(AJob);
      end;
      if Result then
        AtomicIncrement(FPosted);
    end;
  finally
    FLocker.Leave;
  end;
end;

function TQJobGroup.MsgWaitFor(ATimeout: Cardinal): TWaitResult;
var
  AEmpty: Boolean;
begin
  Result := FWaitResult;
  if GetCurrentThreadId <> MainThreadId then
    Result := WaitFor(ATimeout)
  else
  begin
    FLocker.Enter;
    try
      AEmpty := FItems.Count = 0;
      if AEmpty then
        Result := wrSignaled;
    finally
      FLocker.Leave;
    end;
    if Result = wrIOCompletion then
    begin
      AtomicIncrement(FWaitingCount);
      if MsgWaitForEvent(FEvent, ATimeout) = wrSignaled then
        Result := FWaitResult;
      AtomicDecrement(FWaitingCount);
      if Result = wrIOCompletion then
      begin
        Cancel;
        if Result = wrIOCompletion then
          Result := wrTimeout;
      end;
      if FTimeoutCheck then
        Workers.Clear(Self);
      if Result = wrTimeout then
        DoAfterDone;
    end
    else if AEmpty then
      DoAfterDone;
  end;
end;

procedure TQJobGroup.Prepare;
begin
  AtomicIncrement(FPrepareCount);
end;

procedure TQJobGroup.Run(ATimeout: Cardinal);
var
  I: Integer;
  AJob: PQJob;
begin
  if AtomicDecrement(FPrepareCount) = 0 then
  begin
    if ATimeout <> INFINITE then
    begin
      FTimeoutCheck := True;
      Workers.Delay(DoJobsTimeout, ATimeout * 10, nil);
    end;
    FLocker.Enter;
    try
      if FItems.Count = 0 then
        FWaitResult := wrSignaled
      else
      begin
        FWaitResult := wrIOCompletion;
        if ByOrder then
        begin
          AJob := FItems[0];
          if (AJob.PushTime = 0) then
          begin
            if Workers.Post(AJob) = 0 then
              FWaitResult := wrAbandoned
            else
              AtomicIncrement(FPosted);
          end;
        end
        else if (FMaxWorkers <= 0) or (FPosted < FMaxWorkers) then

        begin
          for I := 0 to FItems.Count - 1 do
          begin
            AJob := FItems[I];
            if AJob.PushTime = 0 then
            begin
              if Workers.Post(AJob) = 0 then
              begin
                FWaitResult := wrAbandoned;
                Break;
              end
              else
                AtomicIncrement(FPosted);
              if FPosted = FMaxWorkers then
                Break;
            end;
          end;
        end;
      end;
    finally
      FLocker.Leave;
    end;
    if FWaitResult <> wrIOCompletion then
    begin
      DoAfterDone;
      FEvent.SetEvent;
    end;
    // DebugOut('Posted remain %d',[FPosted]);
  end;
end;

function TQJobGroup.WaitFor(ATimeout: Cardinal): TWaitResult;
var
  AEmpty: Boolean;
begin
  Result := FWaitResult;
  FLocker.Enter;
  try
    AEmpty := FItems.Count = 0;
    if AEmpty then
      Result := wrSignaled;
  finally
    FLocker.Leave;
  end;
  if Result = wrIOCompletion then
  begin
    AtomicIncrement(FWaitingCount);
    if FEvent.WaitFor(ATimeout) = wrSignaled then
      Result := FWaitResult
    else
    begin
      Result := wrTimeout;
      Cancel;
    end;
    AtomicDecrement(FWaitingCount);
    if Result = wrTimeout then
      DoAfterDone;
  end;
  if FTimeoutCheck then
    Workers.Clear;
  if AEmpty then
    DoAfterDone;
end;

function JobPoolCount: NativeInt;
begin
  Result := JobPool.Count;
end;

function JobPoolPrint: QStringW;
var
  AJob: PQJob;
  ABuilder: TQStringCatHelperW;
begin
  ABuilder := TQStringCatHelperW.Create;
  JobPool.FLocker.Enter;
  try
    AJob := JobPool.FFirst;
    while AJob <> nil do
    begin
      ABuilder.Cat(IntToHex(NativeInt(AJob), SizeOf(NativeInt)))
        .Cat(SLineBreak);
      AJob := AJob.Next;
    end;
  finally
    JobPool.FLocker.Leave;
    Result := ABuilder.Value;
    FreeObject(ABuilder);
  end;
end;

{ TQForJobs }
procedure TQForJobs.BreakIt;
begin
  AtomicExchange(FBreaked, 1);
end;

constructor TQForJobs.Create(const AStartIndex, AStopIndex: TForLoopIndexType;
  AData: Pointer; AFreeType: TQJobDataFreeType);
var
  ACount: NativeInt;
begin
  inherited Create;
  FIterator := AStartIndex - 1;
  FStartIndex := AStartIndex;
  FStopIndex := AStopIndex;
  FWorkerCount := GetCPUCount;
  ACount := (AStopIndex - AStartIndex) + 1;
  if FWorkerCount > ACount then
    FWorkerCount := ACount;
  FWorkJob := JobPool.Pop;
  JobInitialize(FWorkJob, AData, AFreeType, True, false);
  FEvent := TEvent.Create();
end;

destructor TQForJobs.Destroy;
begin
  Workers.FreeJob(FWorkJob);
  FreeObject(FEvent);
  inherited;
end;

procedure TQForJobs.DoJob(AJob: PQJob);
var
  I: NativeInt;
begin
  try
    repeat
      I := AtomicIncrement(FIterator);
      if I <= StopIndex then
      begin
{$IFDEF UNICODE}
        if FWorkJob.IsAnonWorkerProc then
          TQForJobProcA(FWorkJob.WorkerProc.ForProcA)(Self, FWorkJob, I)
        else
{$ENDIF}
          if FWorkJob.WorkerProc.Data = nil then
            FWorkJob.WorkerProc.ForProcG(Self, FWorkJob, I)
          else
            PQForJobProc(@FWorkJob.WorkerProc)^(Self, FWorkJob, I);
        AtomicIncrement(FWorkJob.Runs);
      end
      else
        Break;
    until (FIterator > StopIndex) or (FBreaked <> 0) or (AJob.IsTerminated);
  except
    on E: Exception do
  end;
  if AJob.IsTerminated then
    BreakIt;
  if AtomicDecrement(FWorkerCount) = 0 then
    FEvent.SetEvent;
end;
{$IFDEF UNICODE}

class function TQForJobs.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcA; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
var
  AInst: TQForJobs;
begin
  AInst := TQForJobs.Create(AStartIndex, AStopIndex, AData, AFreeType);
  try
    AInst.FWorkJob.WorkerProc.ForProc := nil;
    AInst.FWorkJob.WorkerProc.Data := Pointer(-1);
    TQForJobProcA(AInst.FWorkJob.WorkerProc.Code) := AWorkerProc;
    AInst.Start;
    Result := AInst.Wait(AMsgWait);
  finally
    FreeObject(AInst);
  end;
end;
{$ENDIF}

class function TQForJobs.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcG; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
var
  AInst: TQForJobs;
begin
  AInst := TQForJobs.Create(AStartIndex, AStopIndex, AData, AFreeType);
  try
    AInst.FWorkJob.WorkerProc.ForProcG := AWorkerProc;
    AInst.Start;
    Result := AInst.Wait(AMsgWait);
  finally
    FreeObject(AInst);
  end;
end;

class function TQForJobs.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProc; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
var
  AInst: TQForJobs;
begin
  AInst := TQForJobs.Create(AStartIndex, AStopIndex, AData, AFreeType);
  try
    PQForJobProc(@AInst.FWorkJob.WorkerProc)^ := AWorkerProc;
    AInst.Start;
    Result := AInst.Wait(AMsgWait);
  finally
    FreeObject(AInst);
  end;
end;

function TQForJobs.GetAvgTime: Cardinal;
begin
  if Runs > 0 then
    Result := TotalTime div Runs
  else
    Result := 0;
end;

function TQForJobs.GetBreaked: Boolean;
begin
  Result := FBreaked <> 0;
end;

function TQForJobs.GetRuns: Cardinal;
begin
  Result := FWorkJob.Runs;
end;

function TQForJobs.GetTotalTime: Cardinal;
begin
  Result := FWorkJob.TotalUsedTime;
end;

procedure TQForJobs.Run(AWorkerProc: TQForJobProc; AMsgWait: Boolean);
begin
  PQForJobProc(@FWorkJob.WorkerProc.ForProc)^ := AWorkerProc;
  Start;
  Wait(AMsgWait);
end;

procedure TQForJobs.Run(AWorkerProc: TQForJobProcG; AMsgWait: Boolean);
begin
  FWorkJob.WorkerProc.ForProcG := AWorkerProc;
  Start;
  Wait(AMsgWait);
end;
{$IFDEF UNICODE}

procedure TQForJobs.Run(AWorkerProc: TQForJobProcA; AMsgWait: Boolean);
begin
  TQForJobProcA(FWorkJob.WorkerProc.ForProcA) := AWorkerProc;
  Start;
  Wait(AMsgWait);
end;
{$ENDIF}

procedure TQForJobs.Start;
var
  I: Integer;
begin
  FWorkJob.StartTime := GetTimestamp;
  Workers.DisableWorkers;
  for I := 0 to FWorkerCount - 1 do
    Workers.Post(DoJob, nil);
  Workers.EnableWorkers;
end;

function TQForJobs.Wait(AMsgWait: Boolean): TWaitResult;
begin
  if FWorkerCount > 0 then
  begin
    if AMsgWait then
      Result := MsgWaitForEvent(FEvent, INFINITE)
    else
      Result := FEvent.WaitFor(INFINITE);
    if FBreaked <> 0 then
      Result := wrAbandoned;
  end
  else
    Result := wrSignaled;
  FWorkJob.TotalUsedTime := GetTimestamp - FWorkJob.StartTime;
end;

{ TStaticThread }

procedure TStaticThread.CheckNeeded;
begin
  FEvent.SetEvent;
end;

constructor TStaticThread.Create;
begin
  inherited Create(True);
  FEvent := TEvent.Create(nil, false, false, '');
{$IFDEF MSWINDOWS}
  Priority := tpIdle;
{$ENDIF}
end;

destructor TStaticThread.Destroy;
begin
  FreeObject(FEvent);
  inherited;
end;

procedure TStaticThread.Execute;
var
  ATimeout: Cardinal;
  // 计算末1秒的CPU占用率，如果低于60%且有未处理的作业，则启动更多的工作者来完成作业
  function LastCpuUsage: Integer;
{$IFDEF MSWINDOWS}
  var
    CurSystemTimes: TSystemTimes;
    Usage, Idle: UInt64;
{$ENDIF}
  begin
{$IFDEF MSWINDOWS}
    Result := 0;
    if WinGetSystemTimes(PFileTime(@CurSystemTimes.IdleTime)^,
      PFileTime(@CurSystemTimes.KernelTime)^,
      PFileTime(@CurSystemTimes.UserTime)^) then
    begin
      Usage := (CurSystemTimes.UserTime - FLastTimes.UserTime) +
        (CurSystemTimes.KernelTime - FLastTimes.KernelTime) +
        (CurSystemTimes.NiceTime - FLastTimes.NiceTime);
      Idle := CurSystemTimes.IdleTime - FLastTimes.IdleTime;
      if Usage > Idle then
        Result := (Usage - Idle) * 100 div Usage;
      FLastTimes := CurSystemTimes;
    end;
{$ELSE}
    Result := TThread.GetCPUUsage(FLastTimes);
{$ENDIF}
  end;

begin
{$IFDEF MSWINDOWS}
{$IF RTLVersion>=21}
  NameThreadForDebugging('QStaticThread');
{$IFEND >=2010}
  if Assigned(WinGetSystemTimes) then // Win2000/XP<SP2该函数未定义，不能使用
    ATimeout := 1000
  else
    ATimeout := INFINITE;
{$ELSE}
  ATimeout := 1000;
{$ENDIF}
  while not Terminated do
  begin
    case FEvent.WaitFor(ATimeout) of
      wrSignaled:
        begin
          if Assigned(Workers) and (not Workers.Terminating) and
            (Workers.IdleWorkers = 0) then
            Workers.LookupIdleWorker(false);
        end;
      wrTimeout:
        begin
          if Assigned(Workers) and (not Workers.Terminating) and
            Assigned(Workers.FSimpleJobs) and (Workers.FSimpleJobs.Count > 0)
            and (LastCpuUsage < 60) and (Workers.IdleWorkers = 0) then
            Workers.LookupIdleWorker(True);
        end;
    end;
  end;
  if not Workers.Terminating then
    Workers.FStaticThread := nil;
end;

{ TQJobExtData }

constructor TQJobExtData.Create(AData: Pointer; AOnFree: TQExtFreeEvent);
begin
  inherited Create;
  FOrigin := AData;
  FOnFree := AOnFree;
end;

constructor TQJobExtData.Create(const S: QStringW);
var
  D: PQStringW;
begin
  New(D);
  D^ := S;
  Create(D, DoFreeAsString);
end;
{$IFNDEF NEXTGEN}

constructor TQJobExtData.Create(const S: AnsiString);
var
  D: PAnsiString;
begin
  New(D);
  D^ := S;
  Create(D, DoFreeAsAnsiString);
end;
{$ENDIF}

constructor TQJobExtData.Create(const AParams: array of const);
var
  T: PVariant;
  I: Integer;
begin
  New(T);
  T^ := VarArrayCreate([0, High(AParams)], varVariant);
  for I := 0 to High(AParams) do
  begin
    case AParams[I].VType of
      vtBoolean:
        T^[I] := AParams[I].VBoolean;
      vtObject:
        T^[I] := IntPtr(AParams[I].VObject);
      vtClass:
        T^[I] := IntPtr(AParams[I].VClass);
      vtInterface:
        T^[I] := IUnknown(AParams[I].VInterface);
      vtInteger:
        T^[I] := AParams[I].VInteger;
{$IFNDEF NEXTGEN}
      vtChar:
        T^[I] := AParams[I].VChar;
{$ENDIF !NEXTGEN}
      vtWideChar:
        T^[I] := AParams[I].VWideChar;
      vtExtended:
        T^[I] := AParams[I].VExtended^;
      vtCurrency:
        T^[I] := AParams[I].VCurrency^;
      vtPointer:
        T^[I] := IntPtr(AParams[I].VPointer);
{$IFNDEF NEXTGEN}
      vtPChar:
        T^[I] := AnsiString(AParams[I].VPChar);
{$ENDIF !NEXTGEN}
      vtPWideChar:
        // 2009之前没有UnicodeString
        T^[I] := {$IF RTLVersion<20}WideString{$ELSE}UnicodeString{$IFEND}(AParams[I].VPWideChar);
{$IFNDEF NEXTGEN}
      vtString:
        T^[I] := AParams[I].VString^;
      vtAnsiString:
        T^[I] := AnsiString(AParams[I].VAnsiString);
      vtWideString:
        T^[I] := WideString(AParams[I].VWideString);
{$ENDIF !NEXTGEN}
      vtVariant:
        T^[I] := AParams[I].VVariant^;
      vtInt64:
        T^[I] := AParams[I].VInt64^;
{$IF RTLVersion>=20}
      vtUnicodeString:
        T^[I] := UnicodeString(AParams[I].VUnicodeString);
{$IFEND >=2009}
    end;
  end;
  Create(T, DoFreeAsVariant);
end;

constructor TQJobExtData.Create(const APlan: TQPlanMask; AData: Pointer;
  AFreeType: TQJobDataFreeType);
var
  APlanData: PQJobPlanData;
begin
  New(APlanData);
  APlanData.OriginData := AData;
  APlanData.Plan := APlan;
  APlanData.DataFreeType := AFreeType;
  APlanData.Runnings := 0;
  APlanData.NextTime := APlan.NextTime;
  if AData <> nil then
  begin
    if AFreeType = jdfFreeAsInterface then
      IUnknown(AData)._AddRef
{$IFDEF NEXTGEN}
      // 移动平台下AData的计数需要增加，以避免自动释放
    else if AFreeType = jdfFreeAsObject then
      TObject(AData).__ObjAddRef;
{$ENDIF};
  end;
  Create(APlanData, DoFreeAsPlan);
end;

constructor TQJobExtData.Create(const Value: Integer);
begin
  FOrigin := Pointer(Value);
  inherited Create;
end;

constructor TQJobExtData.Create(const Value: Int64);
{$IFDEF CPUX64}
begin
  FOrigin := Pointer(Value);
  inherited Create;
{$ELSE}
var
  D: PInt64;
begin
  GetMem(D, SizeOf(Int64));
  D^ := Value;
  Create(D, DoSimpleTypeFree);
{$ENDIF}
end;

constructor TQJobExtData.Create(const Value: Boolean);
begin
  FOrigin := Pointer(Integer(Value));
  inherited Create;
end;

constructor TQJobExtData.Create(const Value: Double);
var
  D: PDouble;
begin
  GetMem(D, SizeOf(Double));
  D^ := Value;
  Create(D, DoSimpleTypeFree);
end;

constructor TQJobExtData.CreateAsDateTime(const Value: TDateTime);
begin
  Create(Value);
end;

{$IFDEF UNICODE}

constructor TQJobExtData.Create(AOnInit: TQExtInitEventA;
  AOnFree: TQExtFreeEventA);
begin
  FOnFreeA := AOnFree;
  if Assigned(AOnInit) then
    AOnInit(FOrigin);
  inherited Create;
end;
{$ENDIF}

constructor TQJobExtData.Create(AOnInit: TQExtInitEvent;
  AOnFree: TQExtFreeEvent);
begin
  FOnFree := AOnFree;
  if Assigned(AOnInit) then
    AOnInit(FOrigin);
  inherited Create;
end;

{$IFDEF UNICODE}

constructor TQJobExtData.Create(AData: Pointer; AOnFree: TQExtFreeEventA);
begin
  inherited Create;
  FOrigin := AData;
  FOnFreeA := AOnFree;
end;
{$ENDIF}

destructor TQJobExtData.Destroy;
begin
  if Assigned(Origin) then
  begin
{$IFDEF UNICODE}
    if Assigned(FOnFreeA) then
      FOnFreeA(Origin);
{$ENDIF}
    if Assigned(FOnFree) then
      FOnFree(Origin);
  end;
  inherited;
end;
{$IFNDEF NEXTGEN}

procedure TQJobExtData.DoFreeAsAnsiString(AData: Pointer);
begin
  Dispose(PAnsiString(AData));
end;
{$ENDIF}

procedure TQJobExtData.DoFreeAsVariant(AData: Pointer);
var
  pVar: PVariant;
begin
  pVar := AData;
  Dispose(pVar);
end;

procedure TQJobExtData.DoFreeAsPlan(AData: Pointer);
var
  APlan: PQJobPlanData;
begin
  APlan := AData;
  if APlan.OriginData <> nil then
    Workers.FreeJobData(APlan.OriginData, APlan.DataFreeType);
  Dispose(PQJobPlanData(AData));
end;

procedure TQJobExtData.DoFreeAsString(AData: Pointer);
begin
  Dispose(PQStringW(AData));
end;

procedure TQJobExtData.DoSimpleTypeFree(AData: Pointer);
begin
  FreeMem(AData);
end;
{$IFNDEF NEXTGEN}

function TQJobExtData.GetAsAnsiString: AnsiString;
begin
  Result := PAnsiString(Origin)^;
end;
{$ENDIF}

function TQJobExtData.GetAsBoolean: Boolean;
begin
  Result := Origin <> nil;
end;

function TQJobExtData.GetAsDateTime: TDateTime;
begin
  Result := PDateTime(Origin)^;
end;

function TQJobExtData.GetAsDouble: Double;
begin
  Result := PDouble(Origin)^;
end;

function TQJobExtData.GetAsInt64: Int64;
begin
  Result := PInt64(Origin)^;
end;

function TQJobExtData.GetAsInteger: Integer;
begin
  Result := Integer(Origin);
end;

function TQJobExtData.GetAsPlan: PQJobPlanData;
begin
  Result := Origin;
end;

function TQJobExtData.GetAsString: QStringW;
  function IsFreeBy(AFreeMethod: TQExtFreeEvent): Boolean;
  begin
    Result := MethodEqual(TMethod(FOnFree), TMethod(AFreeMethod));
  end;

begin
  if IsFreeBy(DoFreeAsString) then
    Result := PQStringW(Origin)^
{$IFNDEF NEXTGEN}
  else if IsFreeBy(DoFreeAsAnsiString) then
    Result := AsAnsiString
{$ENDIF}
  else if IsFreeBy(DoFreeAsPlan) then
    Result := AsPlan.Plan.AsString
  else
    Result := '';
end;

function TQJobExtData.GetParamCount: Integer;
begin
  Result := VarArrayHighBound(PVariant(FOrigin)^, 1) + 1;
end;

function TQJobExtData.GetParams(AIndex: Integer): Variant;
begin
  Result := PVariant(FOrigin)^[AIndex];
end;

{$IFNDEF NEXTGEN}

procedure TQJobExtData.SetAsAnsiString(const Value: AnsiString);
begin
  PAnsiString(Origin)^ := Value;
end;
{$ENDIF}

procedure TQJobExtData.SetAsBoolean(const Value: Boolean);
begin
  FOrigin := Pointer(Integer(Value));
end;

procedure TQJobExtData.SetAsDateTime(const Value: TDateTime);
begin
  PDateTime(Origin)^ := Value;
end;

procedure TQJobExtData.SetAsDouble(const Value: Double);
begin
  PDouble(Origin)^ := Value;
end;

procedure TQJobExtData.SetAsInt64(const Value: Int64);
begin
{$IFDEF CPUX64}
  FOrigin := Pointer(Value);
{$ELSE}
  PInt64(FOrigin)^ := Value;
{$ENDIF}
end;

procedure TQJobExtData.SetAsInteger(const Value: Integer);
begin
  FOrigin := Pointer(Value);
end;

procedure TQJobExtData.SetAsString(const Value: QStringW);
begin
  PQStringW(FOrigin)^ := Value;
end;

procedure RunInMainThread(AProc: TMainThreadProc; AData: Pointer); overload;
var
  AHelper: TRunInMainThreadHelper;
begin
  AHelper := TRunInMainThreadHelper.Create;
  AHelper.FProc := AProc;
  AHelper.FData := AData;
  try
    TThread.Synchronize(nil, AHelper.Execute);
  finally
    FreeObject(AHelper);
  end;
end;

procedure RunInMainThread(AProc: TMainThreadProcG; AData: Pointer); overload;
var
  AHelper: TRunInMainThreadHelper;
begin
  AHelper := TRunInMainThreadHelper.Create;
  TMethod(AHelper.FProc).Code := @AProc;
  TMethod(AHelper.FProc).Data := nil;
  AHelper.FData := AData;
  try
    TThread.Synchronize(nil, AHelper.Execute);
  finally
    FreeObject(AHelper);
  end;
end;
{$IFDEF UNICODE}

procedure RunInMainThread(AProc: TThreadProcedure); overload;
begin
  TThread.Synchronize(nil, AProc);
end;
{$ENDIF}
{ TRunInMainThreadHelper }

procedure TRunInMainThreadHelper.Execute;
begin
  if TMethod(FProc).Data = nil then
    TMainThreadProcG(TMethod(FProc).Code)(FData)
  else
    FProc(FData);
end;

{ TQSignalQueue }

procedure TQSignalQueue.Clear;
var
  ANext: PQSignalQueueItem;
begin
  FLocker.Enter;
  try
    while Assigned(FFirst) do
    begin
      if Assigned(FFirst.WaitEvent) then
        TEvent(FFirst.WaitEvent).SetEvent;
      ANext := FFirst.Next;
      FreeAndNilObject(FFirst)  ;
//      FreeAndNil(FFirst);
      FFirst := ANext;
    end;
    FLast := nil;
  finally
    FLocker.Leave;
  end;
end;

constructor TQSignalQueue.Create(AOwner: TQWorkers);
begin
  inherited Create;
  FLocker := TQSimpleLock.Create;
  FOwner := AOwner;
  FMaxItems := 4096;
end;

destructor TQSignalQueue.Destroy;
begin
  Clear;
  FreeAndNil(FLocker);
  inherited;
end;

procedure TQSignalQueue.FireNext;
begin
  FLocker.Enter;
  try
    if Assigned(FLastPop) then
      Exit;
    FLastPop := FFirst;
    if Assigned(FFirst) then
      FFirst := FFirst.Next;
    if not Assigned(FFirst) then
      FLast := nil;
    Dec(FCount);
  finally
    FLocker.Leave;
  end;
  if Assigned(FLastPop) then
    FOwner.FireSignalJob(FLastPop);
end;

procedure TQSignalQueue.FreeItem(AItem: PQSignalQueueItem);
begin
  if Assigned(AItem.Data) and (AItem.FreeType <> jdfFreeByUser) then
    FOwner.FreeJobData(AItem.Data, AItem.FreeType);
  Dispose(AItem);
end;

function TQSignalQueue.InternalPost(AItem: PQSignalQueueItem): Boolean;
var
  ADoFire: Boolean;
begin
  Result := Count < MaxItems;
  if Result then
  begin
    FLocker.Enter;
    if Assigned(FLast) then
      FLast.Next := AItem
    else
      FFirst := AItem;
    FLast := AItem;
    ADoFire := FFirst = FLast;
    Inc(FCount);
    FLocker.Leave;
    if ADoFire then
      FireNext;
  end;
end;

function TQSignalQueue.NewItem(AId: Integer; AData: Pointer;
  AFreeType: TQJobDataFreeType; AWaiter: TEvent): PQSignalQueueItem;
begin
  New(Result);
  Result.Id := AId;
  Result.FreeType := AFreeType;
  Result.Data := AData;
  Result.FireCount := 0;
  Result.RefCount := 0;
  if Assigned(AData) then
  begin
    if AFreeType = jdfFreeAsInterface then
      IInterface(AData)._AddRef
{$IFDEF AUTOREFCOUNT}
    else if AFreeType = jdfFreeAsObject then
      TObject(AData).__ObjAddRef
{$ENDIF}
        ;
  end;
  Result.Next := nil;
  Result.WaitEvent := AWaiter;
{$IFDEF AUTOREFCOUNT}
  if Assigned(AWaiter) then
    AWaiter.__ObjAddRef;
{$ENDIF}
end;

function TQSignalQueue.Post(AId: Integer; AData: Pointer;
  AFreeType: TQJobDataFreeType): Boolean;
begin
  Result := InternalPost(NewItem(AId, AData, AFreeType, nil));
end;

function TQSignalQueue.Post(AName: QStringW; AData: Pointer;
  AFreeType: TQJobDataFreeType): Boolean;
begin
  Result := InternalPost(NewItem(FOwner.RegisterSignal(AName), AData,
    AFreeType, nil));
end;

function TQSignalQueue.Send(AId: Integer; AData: Pointer;
  AFreeType: TQJobDataFreeType; ATimeout: Cardinal): TWaitResult;
var
  AItem: PQSignalQueueItem;
  AEvent: TEvent;
begin
  if ATimeout = 0 then
    AEvent := nil
  else
    AEvent := TEvent.Create(nil, false, false, '');
  AItem := NewItem(AId, AData, AFreeType, AEvent);
  Inc(AItem.RefCount);
  FOwner.FireSignalJob(AItem);
  if Assigned(AEvent) then
  begin
    Result := MsgWaitForEvent(AEvent, ATimeout);
    AtomicExchange(AItem.WaitEvent, nil); // 置空
    FreeAndNil(AEvent);
  end
  else
    Result := wrSignaled;
  if AtomicDecrement(AItem.RefCount) = 0 then
    FreeItem(AItem);
end;

function TQSignalQueue.Send(AName: QStringW; AData: Pointer;
  AFreeType: TQJobDataFreeType; ATimeout: Cardinal): TWaitResult;
begin
  Result := Send(FOwner.RegisterSignal(AName), AData, AFreeType, ATimeout);
end;

procedure TQSignalQueue.SingalJobDone(AItem: PQSignalQueueItem);
begin
  if Assigned(AItem.WaitEvent) then
    TEvent(AItem.WaitEvent).SetEvent;
  if AtomicDecrement(AItem.RefCount) = 0 then
    FreeItem(AItem);
  if AItem = FLastPop then
  begin
    FLastPop := nil;
    FireNext;
  end;
end;

{ TQRunonceTask }
{$IFDEF UNICODE}

procedure TQRunonceTask.Runonce(ACallback: TProc);
begin
  while CanRun = 1 do
  begin
    if AtomicCmpExchange(CanRun, 0, 1) = 1 then
      ACallback;
  end;
end;
{$ENDIF}

procedure TQRunonceTask.Runonce(ACallback: TProcedure);
begin
  while CanRun = 1 do
  begin
    if AtomicCmpExchange(CanRun, 0, 1) = 1 then
      ACallback;
  end;
end;

procedure TQRunonceTask.Runonce(ACallback: TThreadMethod);
begin
  while CanRun = 1 do
  begin
    if AtomicCmpExchange(CanRun, 0, 1) = 1 then
      ACallback;
  end;
end;

{ TQWorkerExt }

constructor TQWorkerExt.Create(AOwner: TQWorker);
begin
  inherited Create;
  FOwner := AOwner;
end;

initialization

GetThreadStackInfo := nil;
AppTerminated := false;
{$IFDEF MSWINDOWS}
GetTickCount64 := GetProcAddress(GetModuleHandle(kernel32), 'GetTickCount64');
WinGetSystemTimes := GetProcAddress(GetModuleHandle(kernel32),
  'GetSystemTimes');
OpenThread := GetProcAddress(GetModuleHandle(kernel32), 'OpenThread');
if not QueryPerformanceFrequency(_PerfFreq) then
begin
  _PerfFreq := -1;
  if Assigned(GetTickCount64) then
    _StartCounter := GetTickCount64
  else
    _StartCounter := GetTickCount;
end
else
  QueryPerformanceCounter(_StartCounter);
{$ELSE}
_Watch := TStopWatch.Create;
_Watch.Start;
{$ENDIF}
_CPUCount := GetCPUCount;
JobPool := TJobPool.Create(1024);
Workers := TQWorkers.Create;

finalization

FreeObject(Workers);
FreeObject(JobPool);

end.
