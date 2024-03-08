using System;
using System.Collections;

namespace SpyroScope {
	class MemorySignature {
		struct Pair {
			public int32 value, mask;
			public int size;

			[Inline]
			public this(int32 value, int32 mask, int size) {
				this.value = value;
				this.mask = mask;
				this.size = size;
			}

			[Inline]
			public static Self Zero<T>() {
				return .(0,-1,sizeof(T));
			}

			[Inline]
			public static Self Wildcard<T>() {
				return .(0,0,sizeof(T));
			}
		}

		List<Pair> signature = new .() ~ delete _;

		public void AddPart<T>(T value, int32 mask = -1) {
			var value;
			signature.Add(.(*(int32*)&value, mask, sizeof(T)));
		}
		
		[Inline]
		public void AddZero<T>() {
			signature.Add(.Zero<T>());
		}
		
		[Inline]
		public void AddWildcard<T>() {
			signature.Add(.Wildcard<T>());
		}

		public enum Op {
			RType	= 0b000000,

			j	= 0b000010,
			jal	= 0b000011,

			beq 	= 0b000100,
			bne 	= 0b000101,
			blez 	= 0b000110,
			bgtz 	= 0b000111,

			addi 	= 0b001000,
			addiu 	= 0b001001,
			slti 	= 0b001010,
			sltiu 	= 0b001011,
			andi 	= 0b001100,
			ori 	= 0b001101,
			xori 	= 0b001110,
			lui 	= 0b001111,

			cop0 = 0b010000,
			cop1 = 0b010001,
			cop2 = 0b010010,

			lb	= 0b100000,
			lbu	= 0b100100,
			lh	= 0b100001,
			lhu	= 0b100101,
			lw	= 0b100011,

			sb	= 0b101000,
			sh	= 0b101001,
			sw	= 0b101011,
		}

		public enum Func {
			sll 	= 0b000000,
			srl 	= 0b000010,
			sra 	= 0b000011,
			sllv 	= 0b000100,
			srlv 	= 0b000110,
			srav 	= 0b000111,
			
			jr  	= 0b001000,
			jalr	= 0b001001,
			
			mfhi 	= 0b010000,
			mthi 	= 0b010001,
			mflo 	= 0b010010,
			mtlo 	= 0b010011,
			mult 	= 0b011000,
			multu 	= 0b011001,
			div 	= 0b011010,
			divu 	= 0b011011,

			add 	= 0b100000,
			addu 	= 0b100001,
			sub  	= 0b100010,
			subu  	= 0b100011,
			and 	= 0b100100,
			or  	= 0b100101,
			xor  	= 0b100110,
			nor 	= 0b100111,
			slt  	= 0b101010,
			sltu  	= 0b101011,
		}

		public enum Reg {
			zero,
			at,
			v0,v1,
			a0,a1,a2,a3,
			t0,t1,t2,t3,t4,t5,t6,t7,
			s0,s1,s2,s3,s4,s5,s6,s7,
			t8,t9,
			k0,k1,
			gp,sp,fp,ra,
				
			wild = -1,
		}

		public void AddOpcode(Op operation) {
			AddPart<int32>((.)operation << 26, (.)0xfc000000);
		}

		public void AddOpcode(Op operation, Reg source = .wild, Reg target = .wild, int immoff = -1) {
			int32 value = (.)operation << 26;
			int32 mask = (.)0xfc000000;

			if (source != .wild) {
				mask |= 0x03e00000;
				value |= (.)source << 21;
			}
			if (target != .wild) {
				mask |= 0x001f0000;
				value |= (.)target << 16;
			}
			if (immoff != -1) {
				mask |= 0x0000ffff;
				value |= (.)immoff;
			}
			AddPart(value, mask);
		}

		[Inline]
		public void AddOpcode(Op operation, int immoff) {
			AddPart(((int32)operation << 26) | (int32)immoff, (.)0xfc00ffff);
		}

		public void AddOpcode(Func func, Reg source = .wild, Reg target = .wild, Reg destination = .wild, int shift = -1) {
			int32 value = (.)func;
			int32 mask = (.)0xfc00003f;

			if (source != .wild) {
				mask |= 0x03e00000;
				value |= (.)source << 21;
			}
			if (target != .wild) {
				mask |= 0x001f0000;
				value |= (.)target << 16;
			}
			if (destination != .wild) {
				mask |= 0x0000f800;
				value |= (.)destination << 11;
			}
			if (shift != -1) {
				mask |= 0x000007c0;
				value |= (.)shift << 6;
			}

			AddPart(value, mask);
		}

		[Inline]
		public void AddOpcode(Func func, Reg source = .wild, Reg target = .wild, int shift = -1) {
			AddOpcode(func, source, target, .wild, shift);
		}

		public void AddOpcode(Op operation, Reg source = .wild, Reg target = .wild, Reg destination = .wild) {
			int32 value = (.)operation << 26;
			int32 mask = (.)0xfc000000;

			if (source != .wild) {
				mask |= 0x03e00000;
				value |= (.)source << 21;
			}
			if (target != .wild) {
				mask |= 0x001f0000;
				value |= (.)target << 16;
			}
			if (destination != .wild) {
				mask |= 0x0000f800;
				value |= (.)destination << 11;
			}
			AddPart(value, mask);
		}

		public Emulator.Address Find(Emulator emulator, Emulator.Address start = (.)0x80000000, Emulator.Address end = (.)0x80200000) {
			var start, end;
			Emulator.Address pre = (.)((uint32)start & 0xffc00000);
			start = (.)((uint32)start & 0x003fffff);
			end = (.)((uint32)end & 0x003fffff);

			int size = 0;
			for (let pair in signature) {
				size += pair.size;
			}
			
			end -= size;
			int8[] buffer = scope .[size * 2];

			Emulator.Address location = start;
			int localLocation = 0;
			emulator.ReadFromRAM(location, &buffer[0], size);

			while (location < end) {
				// Load in the memory into the leading half of buffer
				if ((localLocation % size) == 0) {
					emulator.ReadFromRAM(location + size, &buffer[((localLocation / size) & 1) > 0 ? 0 : size], size);
				}

				// Scan through the signature if it matches
				int pos = localLocation;
				bool match = true;
				for (let pair in signature) {
					int32 sample = *(int32*)(buffer.CArray() + (pos % buffer.Count));
					if (((pair.value ^ sample) & pair.mask) != 0) {
						match = false;
						break;
					}
					
					pos += pair.size;
				}
	
				if (match) {
					return pre | location;
				}
				
				// Always align to first pair if no match found
				location += signature[0].size;
				localLocation += signature[0].size;
			}

			return .Null;
		}

		public void Clear() {
			signature.Clear();
		}

		public Emulator.Address FindReverse(Emulator emulator, Emulator.Address start = (.)0x80200000, Emulator.Address end = (.)0x80000000) {
			var start;

			int size = 0;
			for (let pair in signature) {
				size += pair.size;
			}
			
			start -= size;
			int8[] buffer = scope .[size * 2];

			Emulator.Address location = start;
			int localLocation = 0;
			emulator.ReadFromRAM(location, &buffer[0], size);

			while (location >= end) {
				// Load in the memory into the leading half of buffer
				if (Math.Repeat(localLocation, size) == 0) {
					emulator.ReadFromRAM(location - size, &buffer[((localLocation / size) & 1) > 0 ? 0 : size], size);
				}

				// Scan through the signature if it matches
				int pos = localLocation;
				bool match = true;
				for (let pair in signature) {
					int32 sample = *(int32*)(buffer.CArray() + Math.Repeat(pos, buffer.Count));
					if (((pair.value ^ sample) & pair.mask) != 0) {
						match = false;
						break;
					}
					
					pos += pair.size;
				}

				if (match) {
					return location;
				}
				
				// Always align to first pair if no match found
				location -= signature[0].size;
				localLocation -= signature[0].size;
			}

			return .Null;
		}
	}
}
