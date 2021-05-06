using System;
using System.Diagnostics;
using System.Collections;
using System.IO;

namespace SpyroScope {
	class EmulatorsConfig {
		public static List<EmulatorsConfig> emulators = new .() ~ DeleteContainerAndItems!(_);

		public String processName = new .() ~ delete _;
		public String label = new .() ~ delete _;

		public class Version {
			public String label = new .() ~ delete _;
			public uint moduleSize;

			public String ramModuleName = new .() ~ delete _;
			public List<int> offsetsToRAM = new .() ~ delete _;
			public String vramModuleName = new .() ~ delete _;
			public List<int> offsetsToVRAM = new .() ~ delete _;
		}

		public List<Version> versions = new .() ~ DeleteContainerAndItems!(_);

		public static void Load() {
			var fs = scope StreamReader();
			if (fs.Open("./config/emulators") case .Ok) {
				var lines = fs.Lines;
				defer lines.Dispose();

				StringView line = .();

				while (true) {
					// Skip white space lines
					while (true) {
						if (lines.GetNext() case .Ok) {
							line = lines.Current.Value;
							line.Trim();
	
							if (line.Length > 0) {
								break;
							}
						}
					}

					// Begin parsing config file
					EmulatorsConfig emulatorConfig = new .();
					emulators.Add(emulatorConfig);

					List<StringView> wordChain = scope .();

					// Process Name and Label
					var words = line.Split(' ');

					// Read until current word ends with ".exe"
					while (words.HasMore) {
						var word = TrySilent!(words.GetNext());
						wordChain.Add(word);

						if (word.EndsWith(".exe", .OrdinalIgnoreCase)) {
							break;
						}
					}
					emulatorConfig.processName.Join(" ", wordChain.GetEnumerator());
					wordChain.Clear();

					// Remaining words is the label
					while (words.HasMore) {
						var word = TrySilent!(words.GetNext());
						wordChain.Add(word);
					}
					emulatorConfig.label.Join(" ", wordChain.GetEnumerator());
					wordChain.Clear();

					// Get every version configuration
					while (true) {
						// Version and Size
						Version emulatorVersion = null;

						TrySilent!(lines.GetNext());
						line = lines.Current.Value;
						if (line .. Trim().Length == 0) {
							break;
						}
						
						words = line.Split(' ');

						emulatorVersion = new .();
						emulatorConfig.versions.Add(emulatorVersion);

						emulatorVersion.label.Set(words.GetNext());
						emulatorVersion.moduleSize = UInt64.Parse(words.GetNext(), .HexNumber);

						// RAM Location
						TrySilent!(lines.GetNext());
						line = lines.Current.Value;
						if (line .. Trim().Length == 0) {
							Debug.FatalError(scope String() .. AppendF("Invalid Emulator Config Format - Expected RAM location for {} ({})", emulatorConfig.label, emulatorVersion.label));
						}

						words = line.Split(' ');

						// Read until current word ends with ".exe" or ".dll"
						while (words.HasMore) {
							var word = TrySilent!(words.GetNext());
							wordChain.Add(word);

							if (word.EndsWith(".exe", .OrdinalIgnoreCase) || word.EndsWith(".dll", .OrdinalIgnoreCase)) {
								break;
							}
						}

						var lastWord = wordChain[wordChain.Count - 1];
						if (!(lastWord.EndsWith(".exe", .OrdinalIgnoreCase) || lastWord.EndsWith(".dll", .OrdinalIgnoreCase))) {
							Debug.FatalError(scope String() .. AppendF("Invalid Emulator Config Format - Expected module name for RAM location in {} ({})", emulatorConfig.label, emulatorVersion.label));
						}

						emulatorVersion.ramModuleName.Join(" ", wordChain.GetEnumerator());
						wordChain.Clear();

						while (words.HasMore) {
							emulatorVersion.offsetsToRAM.Add(Int64.Parse(words.GetNext(), .HexNumber));
						}

						// VRAM Location
						TrySilent!(lines.GetNext());
						line = lines.Current.Value;
						if (line .. Trim().Length == 0) {
							Debug.FatalError(scope String() .. AppendF("Invalid Emulator Config Format - Expected VRAM location for {} ({})", emulatorConfig.label, emulatorVersion.label));
						}

						words = line.Split(' ');

						// Read until current word ends with ".exe" or ".dll"
						while (words.HasMore) {
							var word = TrySilent!(words.GetNext());
							wordChain.Add(word);

							if (word.EndsWith(".exe", .OrdinalIgnoreCase) || word.EndsWith(".dll", .OrdinalIgnoreCase)) {
								break;
							}
						}
						
						lastWord = wordChain[wordChain.Count - 1];
						if (!(lastWord.EndsWith(".exe", .OrdinalIgnoreCase) || lastWord.EndsWith(".dll", .OrdinalIgnoreCase))) {
							Debug.FatalError(scope String() .. AppendF("Invalid Emulator Config Format - Expected module name for VRAM location in {} ({})", emulatorConfig.label, emulatorVersion.label));
						}

						emulatorVersion.vramModuleName.Join(" ", wordChain.GetEnumerator());
						wordChain.Clear();

						while (words.HasMore) {
							emulatorVersion.offsetsToVRAM.Add(Int64.Parse(words.GetNext(), .HexNumber));
						}
					}
				}
			}
		}
	}
}
