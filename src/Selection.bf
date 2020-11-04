using System;
using System.Collections;

namespace SpyroScope {
	static class Selection {
		public class SelectionTest {
			function bool(ref float) OnTest;
			function void() OnClear;
			function void() OnSelect;
			function void() OnUnselect;

			public this(function bool(ref float) test, function void() clear, function void() select, function void() unselect) {
				OnTest = test;
				OnClear = clear;
				OnSelect = select;
				OnUnselect = unselect;
			}
			
			public bool Test(ref float depth) => OnTest(ref depth);
			public void Clear() => OnClear();
			public void Select() => OnSelect();
			public void Unselect() => OnUnselect();
		}

		public static List<SelectionTest> selectionTests = new .() ~ DeleteContainerAndItems!(_);
		static SelectionTest passedTest = null;
		static SelectionTest passedSelect = null; 

		public static void Test() {
			if (passedTest != null) {
				passedTest.Clear();
			}

			var depth = float.PositiveInfinity;
			passedTest = null;
			for (let selectionTest in selectionTests) {
				if (selectionTest.Test(ref depth)) {
					if (passedTest != null) {
						passedTest.Clear();
					}
					passedTest = selectionTest;
				}
			}
		}

		public static void Select() {
			if (passedSelect != null) {
				passedSelect.Unselect();
			}

			if (passedTest != null) {
				passedTest.Select();
			}

			passedSelect = passedTest;
			Test();
		}

		public static void Clear() {
			for (let selectionTest in selectionTests) {
				selectionTest.Clear();
			}

			passedTest = null;
		}

		public static void Reset() {
			for (let selectionTest in selectionTests) {
				selectionTest.Clear();
				selectionTest.Unselect();
			}

			passedSelect = passedTest = null;
		}
	}
}
