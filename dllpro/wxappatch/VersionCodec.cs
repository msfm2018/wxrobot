namespace MultiWeixin.Assist;


public class VersionCodec
{
    // 版本号组成部分
    public int Major { get; private set; }
    public int Minor { get; private set; }
    public int Build { get; private set; }
    public int Revision { get; private set; }



    private const int MajorOffset = 238;
    private const int MinorOffset = 84;





    /// <summary>
    /// 通过编码后的整型版本号初始化编解码器（支持大数值）
    /// </summary>
    public VersionCodec(uint encodedVersion)
    {
    
            DecodeFromInteger(encodedVersion);
      
    }

    /// <summary>
    /// 将编码后的整型版本号解码为语义化版本
    /// </summary>
    private void DecodeFromInteger(uint? encodedVersion)
    {
        if (encodedVersion == null)
        {
            throw new ArgumentNullException(nameof(encodedVersion), "编码版本号不能为空");
        }

        uint ev = encodedVersion.Value;
        int encodedMajor = (int)((ev >> 24) & 0xFF);
        int encodedMinor = (int)((ev >> 16) & 0xFF);
        int encodedBuild = (int)((ev >> 8) & 0xFF);
        int encodedRevision = (int)(ev & 0xFF);


        Major = encodedMajor - MajorOffset;
        Minor = encodedMinor - MinorOffset;
        Build = encodedBuild;
        Revision = encodedRevision;

        if (Major < 0 || Minor < 0)
        {
            throw new ArgumentException("解码后的 Major 或 Minor 为负数，无效的编码版本号");
        }

    }




    /// <summary>
    /// 获取语义化版本字符串表示
    /// </summary>
    public override string ToString()
    {
        return $"{Major}.{Minor}.{Build}.{Revision}";
    }
}