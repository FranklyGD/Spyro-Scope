using System;
using System.Diagnostics;
using System.Collections;
using System.IO;

namespace SpyroScope {
	static class ROMsConfig {
		public static Dictionary<int32, String> roms = new .() ~ DeleteDictionaryAndValues!(_);

		public static void Load() {
			var linesRead = 0;
			var fs = scope StreamReader();
			if (fs.Open("./config/roms") case .Ok) {
				String readLine = scope .();
				StringView line = .();

				while (true) {
					// Skip white space lines
					while (true) {
						readLine.Clear();
						if (fs.ReadLine(readLine) case .Ok) {
							linesRead++;
							line = readLine;
							line.Trim();

							if (line.Length > 0) {
								break;
							}
						} else {
							return;
						}
					}
					
					List<StringView> wordChain = scope .();

					var words = line.Split(' ');

					var checksum = words.GetNext();
					while (words.HasMore) {
						var word = TrySilent!(words.GetNext());
						wordChain.Add(word);
					}

					roms.Add(Int32.Parse(checksum, .HexNumber), new String() .. Join(" ", wordChain.GetEnumerator()));
				}
			}
		}
	}
}
