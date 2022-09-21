using System;
using System.Diagnostics;
using System.Threading;

namespace Json.Tests;

static
{
	static mixin Handle(JsonResult res)
	{
		switch(res)
		{
		case .Ok:
		case .Err(let err):
			Debug.WriteLine(err.ToString(.. scope .(32)));
			Test.FatalError();
		}
	}

	[Test]
	static void Reading()
	{
		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("1", tree));
			Test.Assert(tree.root.AsNumber() == 1);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("-1e+1", tree));
			Test.Assert(tree.root.AsNumber() == -1e+1);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("-1E+1", tree));
			Test.Assert(tree.root.AsNumber() == -1e+1);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("1.2", tree));
			Test.Assert(tree.root.AsNumber() == 1.2);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("{}", tree));
			Test.Assert(tree.root.AsObject().Count == 0);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("[]", tree));
			Test.Assert(tree.root.AsArray().Count == 0);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("null", tree));
			Test.Assert(tree.root == .Null);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("true", tree));
			Test.Assert(tree.root.AsBool() == true);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("false", tree));
			Test.Assert(tree.root.AsBool() == false);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("\" \"", tree));
			Test.Assert(tree.root.AsString() == " ");
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("{\"a\":1,\"a\":2}", tree));
			Test.Assert(tree.root.AsObject()["a"].AsNumber() == 2);
		}

		{
			String str = "\u{20AC}";
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("\"\\u20AC\"", tree));
			Test.Assert(tree.root.AsString() == str);
		}

		{
			String str = "\u{20AC}\u{0024}";
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("\"\\u20AC\\u0024\"", tree));
			Test.Assert(tree.root.AsString() == str);
		}

		{
			String str = "\u{0001D11E}";
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("\"\\uD834\\uDD1E\"", tree));
			Test.Assert(tree.root.AsString() == str);
		}

		{
			let tree = scope JsonTree();
			Handle!(Json.ReadJson("""
				{
					"::dwg_entry1": 1 ,
					"" :
						[
							1,
							2 , {},
							"\\" aaaahh \\\\"
						]
				}
				""", tree));
			if (tree.root case .Object(let object) && object["::dwg_entry1"] case .Number(1)
				&& object[""] case .Array(let array) && array[0] case .Number(1) && array[1] case .Number(2)
				&& array[2] case .Object(let object2) && object2.Count == 0 && array[3] case .String("\" aaaahh \\")
				&& tree.root.AsObject()[""].AsArray()[0].AsNumber() == 1)
				NOP!();
			else Test.FatalError();
		}

		// TODO fail tests

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("{", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("[", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("\"", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("\"dave\\", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("\"\\u", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("\"\\\"", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("\"\\u000", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("\"\\u0000\\ug", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("{\"\"}", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("{\"\":{}", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("{\"\":{},", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("{\":{},", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("t", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("f", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("nu", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("0.e1", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("0.", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("0.24.", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("0.2e", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("+1", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("0.24e+-2", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("""
				[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
				[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
				[[]]
				]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]
				]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]
				""", tree) case .Err);
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("""
				[
				1,
				2e-10,
				{"a":true}, .

				]
				""", tree) case .Err(.() {
					column = 13,
					line = 4,
					error = .Syntax_InvalidValue
				}));
		}

		{
			let tree = scope JsonTree();
			Test.Assert(Json.ReadJson("", tree) case .Err(.() {
					column = 1,
					line = 1,
					error = .Syntax_ExpectedValue
				}));
		}

		// BENCH:
		// test with big json > 16 element object
		// -> benching with others, and writing with certain and uncertain sizing
	}

	[Test]
	static void Writing()
	{
		let conincidentalKeyStr = scope String("Oh hello there");
		{
			let tree = scope JsonTree();
			let rootObj = tree.MakeOwnedObject(3);
			tree.root = .Object(rootObj);

			rootObj["CONST STRING!!"] = .Null; // String const

			rootObj[conincidentalKeyStr] = .Bool(false); // Key string is not owned by the json tree, just referenced and exists fully independently

			let treeBoundStr = tree.MakeOwnedString("another one..");
			rootObj[treeBoundStr] = .String(treeBoundStr); // String is tied to lifetime of tree. only for use here!

			let array = tree.MakeOwnedArray(8);
			rootObj["someArrayThing"] = .Array(array);
			for (let i < 8)
				array.Add(.Number(Math.Pow(i, i) / 10));

			let json = Json.WriteJson(tree, .. scope .(128));
			Test.Assert(json == "{\"CONST STRING!!\":null,\"Oh hello there\":false,\"another one..\":\"another one..\",\"someArrayThing\":[0.1,0.1,0.4,2.7,25.6,312.5,4665.6,82354.3]}");
		}
	}
}