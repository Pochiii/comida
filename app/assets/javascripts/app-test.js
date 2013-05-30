QUnit.config.autostart = true;
QUnit.config.requireExpects = true;

module("Default tests", {
	setup: function() {

	},
	teardown: function() {

	}
});

test("This equality test always passes", function() {
	expect(1);
	equal("Hello World", "Hello World", "This test is expected to pass.");
});

test("This non-equality test always passes", function() {
	expect(1);
	notEqual("Hello World", "Hello, World", "This test is expected to pass.");
});

test("This expression test always passes", function() {
	expect(1);
	ok(true, "This is true, so it passes");
});

test("This object comparation test always passes", function() {
	expect(1);
	var obj = {
		"test": "me"
	}
	deepEqual(obj, {
		"test": "me"
	}, "This is the same object");
});

asyncTest("Asynchronous test", function() {
	expect(1);
	setTimeout(function() {
		ok(true, "Passed and ready to go!");
		start();
	}, 300);
});
