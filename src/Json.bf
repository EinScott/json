using System;
using System.Collections;
using System.Diagnostics;

namespace Json;

using internal Json;

typealias JsonResult = Result<void, JsonError>;
typealias JsonObjectData = Dictionary<StringView, JsonElement>;
typealias JsonArrayData = List<JsonElement>;

struct JsonError
{
	public int line, column;
	public JsonErrorType error;

	public override void ToString(String strBuffer)
	{
		strBuffer.Append("Error '");
		error.ToString(strBuffer);
		strBuffer.Append("' at Ln ");
		line.ToString(strBuffer);
		strBuffer.Append(" Col ");
		column.ToString(strBuffer);
	}
}

enum JsonErrorType
{
	Syntax_ExpectedValue,
	Syntax_InvalidValue,
	Syntax_UnterminatedString,
	Syntax_ControlCharInString,
	Synatx_ExpectedEnd,
	Syntax_InvalidEscapeSequence,
	Syntax_UnterminatedObject,
	Syntax_ExpectedKey,
	Syntax_ExpectedColon,
	Syntax_UnterminatedArray,
	Syntax_InvalidNumber,
	Constraint_DuplicateObjectKey,
	Constraint_DepthTooGreat,
	Lib_TreeRootWasAlreadyUsed
}

enum JsonElement
{
	case Null;
	case Object(JsonObjectData object);
	case Array(JsonArrayData array);
	case String(StringView string);
	case Number(double number);
	case Bool(bool boolean);

	public bool AsBool()
	{
		if (this case .Bool(let boolean))
			return boolean;
		Runtime.FatalError();
	}

	public double AsNumber()
	{
		if (this case .Number(let number))
			return number;
		Runtime.FatalError();
	}

	public StringView AsString()
	{
		if (this case .String(let string))
			return string;
		Runtime.FatalError();
	}

	public JsonArrayData AsArray()
	{
		if (this case .Array(let array))
			return array;
		Runtime.FatalError();
	}

	public JsonObjectData AsObject()
	{
		if (this case .Object(let object))
			return object;
		Runtime.FatalError();
	}
}

class JsonTree
{
	internal bool hasContent;
	append BumpAllocator alloc = .();
	public JsonElement root;

	[Inline]
	public JsonObjectData MakeOwnedObject(int reserve = 16) => new:alloc JsonObjectData((int32)reserve);

	[Inline]
	public JsonArrayData MakeOwnedArray(int reserve = 16) => new:alloc JsonArrayData(reserve);

	[Inline]
	public String MakeOwnedString(StringView str) => new:alloc String(str);

	[Inline]
	public String MakeOwnedString(int reserve = 32) => new:alloc String(reserve);
}

static class JsonPrinter
{
	public static void Value(JsonElement el, String buffer)
	{
		switch (el)
		{
		case .Object(let object):
			buffer.Append('{');
			if (object.Count > 0)
			{
				for (let pair in object)
				{
					buffer.Append('"');
					buffer.Append(pair.key);
					buffer.Append("\":");

					Value(pair.value, buffer);

					buffer.Append(',');
				}
				buffer.RemoveFromEnd(1);
			}
			buffer.Append('}');
		case .Array(let array):
			buffer.Append('[');
			if (array.Count > 0)
			{
				for (let value in array)
				{
					Value(value, buffer);
					buffer.Append(',');
				}
				buffer.RemoveFromEnd(1);
			}
			buffer.Append(']');
		case .String(let string):
			buffer.Append('"');
			buffer.Append(string);
			buffer.Append('"');
		case .Number(let number):
			number.ToString(buffer);
		case .Bool(true):
			buffer.Append("true");
		case .Bool(false):
			buffer.Append("false");
		case .Null:
			buffer.Append("null");
		default:
			Runtime.FatalError();
		}
	}
}

static class Json
{
	public static int readerMaxDepth = 0x100;
	public enum DuplicateKeyBehavior
	{
		Override,
		Error
	}
	public static DuplicateKeyBehavior readerDuplicateKeyBehavior;

	public static JsonResult ReadJson(StringView jsonString, JsonTree unusedTree)
	{
		if (unusedTree.hasContent)
			return .Err(.() {
				error = .Lib_TreeRootWasAlreadyUsed
			});
		unusedTree.hasContent = true;

		let builder = scope JsonBuilder(unusedTree);
		return builder.Build(jsonString, ref unusedTree.root);
	}

	[Inline]
	public static void WriteJson(JsonTree tree, String jsonBuffer)
	{
		JsonPrinter.Value(tree.root, jsonBuffer);
	}
}