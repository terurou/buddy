package ;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.rtti.Meta;
using haxe.macro.ExprTools;
import AutoIncluder;
using Lambda;

@:autoBuild(BDDMainClass.build()) interface BDD { }

class BDDMainClass
{
	macro public static function build() : Array<Field>
	{
		var cls = Context.getLocalClass().get();
		var fields = Context.getBuildFields();
		var found = false;

		AutoIncluder.run(cls, typeIsSuite);

		for (f in fields)
		{
			if (f.name == "main" && f.access.exists(function(a) { return a == Access.AStatic; } ))
			{
				switch(f.kind)
				{
					case FFun(f2):
						switch(f2.expr.expr)
						{
							case EBlock(exprs):
								found = true;
								buildMain(exprs, cls);
							case _:
						}
					case _:
				}
			}
		}

		if (!found)
		{
			var body = macro {};
			switch(body.expr)
			{
				case EBlock(exprs):
					buildMain(exprs, cls);
				case _:
			}

			var func = {
				ret: null,
				params: [],
				expr: body,
				args: []
			};

			var main = {
				pos: Context.currentPos(),
				name: "main",
				meta: [],
				kind: FFun(func),
				doc: null,
				access: [Access.AStatic, Access.APublic]
			};

			fields.push(main);
		}

		return fields;
	}

	private static function typeIsSuite(type : ClassType) : Bool
	{
		var superClass = type.superClass;
		return superClass != null && superClass.t.get().name == "BDDSuite";
	}

	private static function buildMain(exprs : Array<Expr>, cls : ClassType)
	{
		var e = AutoIncluder.toTypeString(cls);
		var body = macro {
			var reporter = new ConsoleReporter();
			var suites = [];
			for (a in haxe.rtti.Meta.getType($i{e}).autoIncluded) {
				suites.push(Type.createInstance(Type.resolveClass(a), []));
			}

			var testsRunning = true;
			new BDDSuiteRunner(suites, reporter).run().then(function(_) { testsRunning = false; } );
			while (testsRunning) Sys.sleep(0.1);
		};

		exprs.push(body);
	}
}