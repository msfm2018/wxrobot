using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;


public class HexStringToIntArrayConverter : JsonConverter<byte[]>
    {
        public override byte[] Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.String)
            {
                throw new JsonException("Expected string for position property.");
            }

            string hexString = reader.GetString() ?? string.Empty;
            if (string.IsNullOrWhiteSpace(hexString))
            {
                return Array.Empty<byte>();
            }

            // 移除 "0x" 前缀，并按逗号分割
            return hexString.Split(',')
                            .Select(s => s.Trim().Replace("0x", ""))
                            .Where(s => !string.IsNullOrWhiteSpace(s))
                            .Select(s => byte.Parse(s, System.Globalization.NumberStyles.HexNumber)) // 解析十六进制字符串为整数
                            .ToArray();
        }

        public override void Write(Utf8JsonWriter writer, byte[] value, JsonSerializerOptions options)
        {
            // 如果需要将 int[] 序列化回十六进制字符串，可以在这里实现
            // 对于这个应用场景，可能不需要反向序列化
            if (value == null)
            {
                writer.WriteNullValue();
            }
            else
            {
                writer.WriteStringValue(string.Join(", ", value.Select(i => $"0x{i:X2}")));
            }
        }
    }



