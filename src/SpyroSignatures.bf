namespace SpyroScope {
	extension Emulator {
		void FindAddressLocations() {
			Emulator.Address signatureLocation, loadSignatureLocation;
			int32[2] loadAddress = ?;

			// Terrain Collision Signature
			MemorySignature terrainCollisionSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.addiu)
			..AddOpcode(.lw)
			..AddOpcode(.sll)
			..AddOpcode(.sll)
			..AddOpcode(.add)
			..AddOpcode(.lw);

			signatureLocation = terrainCollisionSignature.Find(this);
			if (signatureLocation.IsNull) {
				return;
			}
			ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
			collisionDataPointer = (.)((int32)loadAddress[0] & 0x0000ffff);
			ReadFromRAM(signatureLocation, &loadAddress, 8);
			collisionDataPointer += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

			romTesterAddresses[4] = (.)signatureLocation;

			// Mobys (Objects) Signature
			MemorySignature mobyArraySignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddWildcard<int32>()
			..AddOpcode(.subu)
			..AddOpcode(.sll)
			..AddOpcode(.subu)
			..AddOpcode(.sll)
			..AddOpcode(.addu)
			..AddOpcode(.sll)
			..AddOpcode(.addu)
			..AddOpcode(.sll)
			..AddOpcode(.subu)
			..AddOpcode(.sll)
			..AddOpcode(.addu)
			..AddOpcode(.subu);

			signatureLocation = mobyArraySignature.Find(this);
			if (signatureLocation.IsNull) {
				return;
			}
			ReadFromRAM(signatureLocation, &loadAddress, 8);
			mobyArrayPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			
			romTesterAddresses[0] = (.)signatureLocation;

			// Moby Models Signature
			// Spyro 1 Attempt
			MemorySignature mobyModelArraySignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddOpcode(.sll)
			..AddOpcode(.addu)
			..AddOpcode(.lui)
			..AddOpcode(.lbu);

			signatureLocation = mobyModelArraySignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				mobyModelArraySignature..Clear()
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.addiu)
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.lw);
				
				signatureLocation = mobyModelArraySignature.Find(this);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				mobyModelArrayPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

				installment = .YearOfTheDragon; //TODO: Temporary representation for 2/3 - Find a distinguishing factor!
			} else {
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				mobyModelArrayPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

				installment = .SpyroTheDragon;
			}

			if (signatureLocation.IsNull) {
				return;
			}
			
			romTesterAddresses[1] = (.)signatureLocation;

			// Terrain Animations Signature
			MemorySignature loadMainSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.addiu)
			..AddOpcode(.lw);

			MemorySignature terrainGeometryAnimationsSignature = scope .()
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.sll)
			..AddOpcode(.add)
			..AddOpcode(.beq)
			..AddOpcode(.lw);

			Address*[3] terrainGeometryAnimationAddresses = .(
				&textureSwappersPointer,
				&textureScrollersPointer,
				&collisionDeformPointer
			);

			signatureLocation = (.)0x80000000;
			for (let i < 3) {
				let addr = terrainGeometryAnimationAddresses[i];

				signatureLocation = terrainGeometryAnimationsSignature.Find(this, signatureLocation + 4);
				if (signatureLocation.IsNull) {
					return;
				}
				
				ReadFromRAM(signatureLocation, &loadAddress, 4);
				*addr = (.)((int32)loadAddress[0] & 0x0000ffff);
				MemorySignature.Reg animsRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

				if (i == 0) {
					loadSignatureLocation = loadMainSignature.Find(this, signatureLocation);
					ReadFromRAM(loadSignatureLocation + 4*2, &loadAddress, 4);
					textureDataPointer = (.)((int32)loadAddress[0] & 0x0000ffff);
					ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
					textureDataPointer += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

					romTesterAddresses[5] = (.)loadSignatureLocation;
				}

				MemorySignature loadSignature = scope .()
				..AddOpcode(.lui, .wild, animsRegister, -1)
				..AddOpcode(.addiu, animsRegister, animsRegister, -1);

				loadSignatureLocation = loadSignature.FindReverse(this, signatureLocation);
				ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				*addr += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			MemorySignature terrainTextureAnimationsSignature = scope .()
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.addi)
			..AddOpcode(.sll)
			..AddOpcode(.add)
			..AddOpcode(.beq)
			..AddOpcode(.addi);

			Address*[3] terrainTextureAnimationAddresses = .(
				&farRegionsDeformPointer,
				null,
				&nearRegionsDeformPointer
			);

			for (let i < 3) {
				let addr = terrainTextureAnimationAddresses[i];

				signatureLocation = terrainTextureAnimationsSignature.Find(this, signatureLocation + 4);
				if (signatureLocation.IsNull) {
					return;
				}
				
				if (addr != null) {
					ReadFromRAM(signatureLocation, &loadAddress, 4);
					*addr = (.)((int32)loadAddress[0] & 0x0000ffff);
					MemorySignature.Reg animsRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

					if (i == 0) {
						loadSignatureLocation = loadMainSignature.Find(this, signatureLocation);
						ReadFromRAM(loadSignatureLocation + 4*2, &loadAddress, 4);
						sceneRegionsPointer = (.)((int32)loadAddress[0] & 0x0000ffff);
						ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
						sceneRegionsPointer += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

						romTesterAddresses[6] = (.)loadSignatureLocation;
					}

					MemorySignature loadSignature = scope .()
					..AddOpcode(.lui, .wild, animsRegister, -1)
					..AddOpcode(.addiu, animsRegister, animsRegister, -1);

					loadSignatureLocation = loadSignature.FindReverse(this, signatureLocation);
					ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
					*addr += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				}
			}

			// Load State Signature
			// Spyro 2/3 Attempt
			MemorySignature loadStateSignature = scope .()
			..AddOpcode(.sw)
			..AddOpcode(.jal)
			..AddOpcode(.sw)
			..AddWildcard<uint32>()
			..AddOpcode(.sll)
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddOpcode(.sll);

			signatureLocation = loadStateSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				loadStateSignature..Clear()
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.addiu, .wild, .wild, 1)
				..AddOpcode(.lui)
				..AddOpcode(.sw);

				signatureLocation = loadStateSignature.Find(this);
				ReadFromRAM(signatureLocation + 4*5, &loadAddress, 8);
				loadStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				ReadFromRAM(signatureLocation + 4*5, &loadAddress, 8);
				loadStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			if (signatureLocation.IsNull) {
				return;
			}

			romTesterAddresses[2] = (.)signatureLocation + 4*5;

			// Game State Signature
			// Spyro 1 Attempt
			MemorySignature gameStateSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddOpcode(.sll)
			..AddOpcode(.beq)
			..AddWildcard<uint32>()
			..AddOpcode(.bne)
			..AddWildcard<uint32>()
			..AddOpcode(.jal)
			..AddOpcode(.sll)
			..AddOpcode(.j)
			..AddOpcode(.sll)
			..AddOpcode(.bne)
			..AddWildcard<uint32>()
			..AddOpcode(.jal)
			..AddOpcode(.sll)
			..AddOpcode(.j)
			..AddOpcode(.sll);

			signatureLocation = gameStateSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				gameStateSignature..Clear()
				..AddOpcode(.jal)
				..AddOpcode(.sll)
				..AddOpcode(.jal)
				..AddOpcode(.sll)
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.sll)
				..AddOpcode(.sltiu)
				..AddOpcode(.beq)
				..AddOpcode(.sll)
				..AddOpcode(.lui)
				..AddOpcode(.addu)
				..AddOpcode(.lw)
				..AddOpcode(.sll);
				
				signatureLocation = gameStateSignature.Find(this);
				ReadFromRAM(signatureLocation + 4*4, &loadAddress, 8);
				gameStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

				romTesterAddresses[3] = (.)signatureLocation + 4*4;
			} else {
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				gameStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				
				romTesterAddresses[3] = (.)signatureLocation;
			}

			if (signatureLocation.IsNull) {
				return;
			}

			// Spyro & Camera Signature
			// Spyro 2/3 Attempt
			MemorySignature spyroCamSignature = scope .()
			..AddOpcode(.sw)
			..AddOpcode(.sw)
			..AddOpcode(.sw)
			..AddOpcode(.sw)
			..AddOpcode(.sw)
			..AddOpcode(.sw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.sub)
			..AddOpcode(.sub)
			..AddOpcode(.sub)
			..AddOpcode(.lw, 0x0)
			..AddOpcode(.lw, 0x4)
			..AddOpcode(.lw, 0x8)
			..AddOpcode(.lw, 0xc)
			..AddOpcode(.lw, 0x10)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4);
			
			MemorySignature.Reg spyroRegister;
			MemorySignature.Reg cameraRegister;

			signatureLocation = spyroCamSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				spyroCamSignature..Clear()
				..AddOpcode(.lw)
				..AddOpcode(.lw)
				..AddOpcode(.lw)
				..AddOpcode(.lw)
				..AddOpcode(.lw)
				..AddOpcode(.lw)
				..AddOpcode(.sub)
				..AddOpcode(.sub)
				..AddOpcode(.sub)
				..AddOpcode(.lw, 0x0)
				..AddOpcode(.lw, 0x4)
				..AddOpcode(.lw, 0x8)
				..AddOpcode(.lw, 0xc)
				..AddOpcode(.lw, 0x10)
				..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0)
				..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1)
				..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2)
				..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3)
				..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4);

				signatureLocation = spyroCamSignature.Find(this);
				if (!signatureLocation.IsNull) {
					ReadFromRAM(signatureLocation, &loadAddress, 4);
					spyroRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
					ReadFromRAM(signatureLocation + 4*3, &loadAddress, 4);
					cameraRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

					MemorySignature cameraSignature = scope .()
					..AddOpcode(.lui, .wild, cameraRegister, -1)
					..AddOpcode(.addiu, cameraRegister, cameraRegister, -1);
					MemorySignature spyroSignature = scope .()
					..AddOpcode(.lui, .wild, spyroRegister, -1)
					..AddOpcode(.addiu, spyroRegister, spyroRegister, -1);

					loadSignatureLocation = cameraSignature.FindReverse(this, signatureLocation);
					ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
					cameraAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
					loadSignatureLocation = spyroSignature.FindReverse(this, signatureLocation);
					ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
					spyroAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				}
			} else {
				ReadFromRAM(signatureLocation + 4*6, &loadAddress, 4);
				spyroRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
				ReadFromRAM(signatureLocation + 4*9, &loadAddress, 4);
				cameraRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
				
				MemorySignature cameraSignature = scope .()
				..AddOpcode(.lui, .wild, cameraRegister, -1)
				..AddOpcode(.addiu, cameraRegister, cameraRegister, -1);
				MemorySignature spyroSignature = scope .()
				..AddOpcode(.lui, .wild, spyroRegister, -1)
				..AddOpcode(.addiu, spyroRegister, spyroRegister, -1);

				loadSignatureLocation = cameraSignature.FindReverse(this, signatureLocation);
				ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				cameraAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				loadSignatureLocation = spyroSignature.FindReverse(this, signatureLocation);
				ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				spyroAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			spyroPositionAddress = (.)spyroAddress;

			MemorySignature cameraPositionSignature = scope .()
			..AddOpcode(.lui) // Camera Struct
			..AddOpcode(.addiu)
			..AddOpcode(.lw) // Camera Basis
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4)
			..AddOpcode(.cop2, (.)0b00110, .zero, (MemorySignature.Reg)5)
			..AddOpcode(.cop2, (.)0b00110, .zero, (MemorySignature.Reg)6)
			..AddOpcode(.cop2, (.)0b00110, .zero, (MemorySignature.Reg)7)
			..AddOpcode(.lw) // Camera Position
			..AddOpcode(.lw)
			..AddOpcode(.lw);

			signatureLocation = cameraPositionSignature.Find(this);
			ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
			cameraBasisAddress = (.)(cameraAddress + (loadAddress[0] & 0x0000ffff));
			ReadFromRAM(signatureLocation + 4*15, &loadAddress, 4);
			cameraPositionAddress = (.)(cameraAddress + (loadAddress[0] & 0x0000ffff));

			// Camera Euler Signature
			// Spyro 1 Attempt
			MemorySignature cameraEulerSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.addiu)
			..AddOpcode(.lh)
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddWildcard<int32>() // lui/ori
			..AddOpcode(.sh)
			..AddOpcode(.jal);

			signatureLocation = cameraEulerSignature.Find(this);
			if (!signatureLocation.IsNull) {
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				cameraEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				cameraEulerAddress -= 2;
			} else {
				// Spyro 2/3 Attempt
				cameraEulerSignature..Clear()
				..AddOpcode(.lui)
				..AddOpcode(.lhu)
				..AddOpcode(.lui)
				..AddOpcode(.lhu)
				..AddOpcode(.lui)
				..AddOpcode(.lhu)
				..AddOpcode(.lui)
				..AddOpcode(.sh)
				..AddOpcode(.lui)
				..AddOpcode(.sh)
				..AddOpcode(.lui)
				..AddOpcode(.sh);

				signatureLocation = cameraEulerSignature.Find(this);
				ReadFromRAM(signatureLocation + 4*6, &loadAddress, 8);
				cameraEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Spyro Euler Signature
			// Spyro 1 Attempt
			MemorySignature spyroEulerSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddOpcode(.addu)
			..AddOpcode(.andi)
			..AddOpcode(.sw)
			..AddOpcode(.sra, .wild, .wild, 4);

			signatureLocation = spyroEulerSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				spyroEulerSignature..Clear()
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.sra)
				..AddOpcode(.sb)
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.sra)
				..AddOpcode(.sb)
				..AddOpcode(.sra);
				
				signatureLocation = spyroEulerSignature.Find(this);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Spyro Basis Signature
			MemorySignature spyroBasisSignature = scope .()
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4);

			signatureLocation = (.)0x80000000;
			while (signatureLocation < (.)0x80200000) {
				signatureLocation = spyroBasisSignature.Find(this, signatureLocation + 4);
				if (signatureLocation.IsNull) {
					break;
				}

				ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
				int spyroBasisOffset = loadAddress[0] & 0x0000ffff;

				MemorySignature spyroSignature2 = scope .()
				..AddOpcode(.lui, .wild, spyroRegister, -1)
				..AddOpcode(.addiu, spyroRegister, spyroRegister, -1);

				loadSignatureLocation = spyroSignature2.FindReverse(this, signatureLocation);
				ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				if (spyroAddress == (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1])) {
					spyroBasisAddress = (.)spyroAddress + spyroBasisOffset;
					break;
				}
			}

			// Spyro Velocity Signature
			MemorySignature spyroVelSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.addiu)
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddOpcode(.sll, .zero, .zero)
			..AddOpcode(.sll)
			..AddOpcode(.subu);

			signatureLocation = spyroVelSignature.Find(this);
			if (signatureLocation.IsNull) {
				MemorySignature spyVelPhySignature = scope .()
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.sw)
				..AddOpcode(.jal);

				signatureLocation = spyVelPhySignature.Find(this);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroVelocityIntended = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

				MemorySignature spyVelIntSignature = scope .()
				..AddOpcode(.lui)
				..AddOpcode(.addiu)
				..AddOpcode(.jal)
				..AddOpcode(.sll)
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.addiu, .zero, .wild, -1)
				..AddOpcode(.lui)
				..AddOpcode(.sw);

				signatureLocation = spyVelIntSignature.Find(this);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroVelocityPhysics = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroVelocityIntended = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				ReadFromRAM(signatureLocation + 4*2, &loadAddress, 8);
				spyroVelocityPhysics = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Spyro State Signature
			// Spyro 2/3 Attempt
			MemorySignature spyroStateSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.sb, .wild, .zero, -1)
			..AddOpcode(.lui)
			..AddOpcode(.sb, .wild, .zero, -1)
			..AddOpcode(.lui)
			..AddOpcode(.sw, .wild, .zero, -1)
			..AddOpcode(.lui)
			..AddOpcode(.sw)
			..AddOpcode(.lui)
			..AddOpcode(.sw, .wild, .zero, -1)
			..AddOpcode(.lui)
			..AddOpcode(.sw)
			..AddOpcode(.lw)
			..AddOpcode(.lw)
			..AddOpcode(.lw);

			signatureLocation = spyroStateSignature.Find(this);

			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				spyroStateSignature..Clear()
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.lui)
				..AddOpcode(.sw);
				
				spyroStateChangeAddress = (.)spyroStateSignature.Find(this) + 4*2;
				ReadFromRAM(spyroStateChangeAddress, &loadAddress, 8);
				spyroStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				spyroStateChangeAddress = (.)signatureLocation + 4*6;
				ReadFromRAM(spyroStateChangeAddress, &loadAddress, 8);
				spyroStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Spyro Animation State Signature
			MemorySignature spyroAnimStateSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.sb)
			..AddOpcode(.sll)
			..AddOpcode(.lui);

			signatureLocation = spyroAnimStateSignature.Find(this);
			
			ReadFromRAM(signatureLocation, &loadAddress, 8);
			spyroAnimStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

			// Background Clear Color Signature
			MemorySignature clearColorSignature = scope .()
			..AddOpcode(.sll, .wild, .wild, 0x4)
			..AddOpcode(.andi, .wild, .wild, 0xff0)
			..AddOpcode(.srl, .wild, .wild, 0x4)
			..AddOpcode(.andi, .wild, .wild, 0xff0)
			..AddOpcode(.srl, .wild, .wild, 0xc)
			..AddOpcode(.andi, .wild, .wild, 0xff0)
			..AddOpcode(.lw)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)21)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)22)
			..AddOpcode(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)23);

			signatureLocation = clearColorSignature.Find(this);
			if (!signatureLocation.IsNull) {
				ReadFromRAM(signatureLocation, &loadAddress, 4);
				MemorySignature.Reg colorRegister = (.)((loadAddress[0] & 0x001f0000) >> 16);

				MemorySignature clearColorLoadSignature = scope .()
				..AddOpcode(.lui, .wild, colorRegister, -1)
				..AddOpcode(.addiu, colorRegister, colorRegister, -1);

				signatureLocation = clearColorLoadSignature.FindReverse(this, signatureLocation);
				ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
				clearColorAddress = (.)((int32)loadAddress[0] & 0x0000ffff);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				clearColorAddress += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Terrain Flags Signature
			MemorySignature terrainFlagsSignature = scope .() ////
			..AddOpcode(.andi, 0x3f)
			..AddOpcode(.addiu, .zero, .wild, 0x3f)
			..AddOpcode(.beq)
			..AddOpcode(.sll)
			..AddOpcode(.lui)
			..AddOpcode(.lw);
			
			signatureLocation = terrainFlagsSignature.Find(this);
			ReadFromRAM(signatureLocation + 4*4, &loadAddress, 8);
			collisionFlagsPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

			// Health
			// Spyro 2/3 Attempt
			MemorySignature healthSignature = scope .() ////
			..AddOpcode(.addiu, .zero, .wild, (uint16)-1)
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddOpcode(.sll)
			..AddWildcard<int32>()
			..AddOpcode(.addiu)
			..AddOpcode(.lui)
			..AddOpcode(.sw);

			signatureLocation = healthSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				healthSignature..Clear()
				..AddOpcode(.bne)
				..AddOpcode(.sll)
				..AddOpcode(.lw)
				..AddOpcode(.sll)
				..AddOpcode(.addiu, .wild, .wild, (uint16)-1)
				..AddOpcode(.sw);

				signatureLocation = healthSignature.Find(this);
				if (!signatureLocation.IsNull) {
					ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
					MemorySignature.Reg healthRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

					MemorySignature loadSignature = scope .()
					..AddOpcode(.lui, .wild, healthRegister, -1)
					..AddOpcode(.addiu, healthRegister, healthRegister, -1);

					loadSignatureLocation = loadSignature.FindReverse(this, signatureLocation);
					ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
					healthAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				}
			} else {
				ReadFromRAM(loadSignatureLocation + 4*1, &loadAddress, 8);
				healthAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Update Spyro Call Signature
			// Spyro 2/3 Attempt
			MemorySignature spyroUpdateCallSignature = scope .()
			..AddOpcode(.andi, 0x8)
			..AddOpcode(.beq)
			..AddOpcode(.andi, 0x20)
			..AddOpcode(.jal)
			..AddOpcode(.sll)
			..AddOpcode(.andi, 0x20);

			signatureLocation = spyroUpdateCallSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				spyroUpdateCallSignature.Clear();

				MemorySignature spyroUpdateSignature = scope .()
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.addiu)
				..AddOpcode(.sw)
				..AddOpcode(.sw)
				..AddOpcode(.andi)
				..AddWildcard<int32>()
				..AddOpcode(.sw)
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.sll);

				// Find start of update function
				signatureLocation = spyroUpdateSignature.Find(this);
				spyroUpdateCallValue = ((uint32)MemorySignature.Op.jal << 26) | (((.)signatureLocation >> 2) & 0x03ffffff);

				spyroUpdateCallSignature.AddPart(spyroUpdateCallValue);

				// Find the third occurrence
				signatureLocation = (.)0x80000000;
				for (let i < 3) {
					signatureLocation = spyroUpdateCallSignature.Find(this, signatureLocation + 4);
					if (signatureLocation.IsNull) {
						break;
					}
				}

				spyroUpdateCallAddress = (.)signatureLocation;
			} else {
				spyroUpdateCallAddress = (.)signatureLocation + 4*3;
				spyroUpdateCallAddress.Read(&spyroUpdateCallValue);
			}

			// Update Camera Call Signature
			// Spyro 2/3 Attempt
			MemorySignature cameraUpdateCallSignature = scope .()
			..AddOpcode(.jalr)
			..AddOpcode(.sll)
			..AddOpcode(.jal)
			..AddOpcode(.sll)
			..AddOpcode(.andi, 0x10)
			..AddOpcode(.beq)
			..AddWildcard<int32>()
			..AddOpcode(.jal)
			..AddOpcode(.sll);
			
			signatureLocation = cameraUpdateCallSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				cameraUpdateCallSignature..Clear()
				..AddOpcode(.bne)
				..AddOpcode(.sll)
				..AddOpcode(.jal)
				..AddOpcode(.sll)
				..AddOpcode(.j)
				..AddOpcode(.sll)
				..AddOpcode(.jal)
				..AddOpcode(.sll)
				..AddOpcode(.lui)
				..AddOpcode(.lw);
				
				signatureLocation = cameraUpdateCallSignature.Find(this);
				cameraUpdateCallAddress = (.)signatureLocation + 4*6;
				cameraUpdateCallAddress.Read(&cameraUpdateCallValue);
			} else {
				cameraUpdateCallAddress = (.)signatureLocation + 4*7;
				cameraUpdateCallAddress.Read(&cameraUpdateCallValue);
			}

			// Main Update Call Signature
			// Spyro 1 Attempt
			MemorySignature updateCallSignature = scope .()
			..AddOpcode(.sb)
			..AddOpcode(.jal)
			..AddOpcode(.sll)
			..AddOpcode(.lw)
			..AddOpcode(.sb)
			..AddOpcode(.sw);
			
			signatureLocation = updateCallSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				updateCallSignature..Clear()
				..AddOpcode(.jal)
				..AddOpcode(.sll)
				..AddOpcode(.jal)
				..AddOpcode(.sll)
				..AddOpcode(.j)
				..AddOpcode(.sll);
				
				signatureLocation = updateCallSignature.Find(this);
				updateCallAddress = (.)signatureLocation;
				updateCallAddress.Read(&updateCallValue);
			} else {
				updateCallAddress = (.)signatureLocation + 4*1;
				updateCallAddress.Read(&updateCallValue);
			}

			// Game Input Signature
			// Spyro 1 Attempt
			MemorySignature gameInputSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.lw)
			..AddOpcode(.sll)
			..AddOpcode(.andi, 0x10)
			..AddOpcode(.beq)
			..AddOpcode(.lui);
			
			signatureLocation = gameInputSignature.Find(this);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				gameInputSignature..Clear()
				..AddOpcode(.lui)
				..AddOpcode(.lw)
				..AddOpcode(.sll)
				..AddOpcode(.andi, 0x10)
				..AddOpcode(.bne);
				
				signatureLocation = gameInputSignature.Find(this);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				gameInputAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				gameInputAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Visual Terrain Warp
			// Spyro 2/3 Attempt
			MemorySignature terrainWarpSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.addiu)
			..AddOpcode(.lw, 0x1c)
			..AddOpcode(.lw, 0x0)
			..AddOpcode(.lw)
			..AddOpcode(.lui);

			signatureLocation = terrainWarpSignature.Find(this);
			if (!signatureLocation.IsNull) {
				ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
				regionsWarpPointer = (.)((int32)loadAddress[0] & 0x0000ffff);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				regionsWarpPointer += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				
				ReadFromRAM(signatureLocation + 4*5, &loadAddress, 8);
				regionsRenderingArrayAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

				ReadFromRAM(signatureLocation + 4*12, &loadAddress, 8);
				frameClockAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				// Spyro 1 Attempt
				MemorySignature regionRenderCullingSignature = scope .()
				..AddOpcode(.lw)
				..AddOpcode(.lw)
				..AddOpcode(.lw)
				..AddOpcode(.sra, .wild, .wild, 0x4)
				..AddOpcode(.sra, .wild, .wild, 0x4)
				..AddOpcode(.sra, .wild, .wild, 0x4)
				..AddOpcode(.lui)
				..AddOpcode(.addiu);

				signatureLocation = regionRenderCullingSignature.Find(this);
				ReadFromRAM(signatureLocation + 4*6, &loadAddress, 8);
				regionsRenderingArrayAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Skybox
			// Spyro 2/3 Attempt
			MemorySignature skyboxSignature = scope .()
			..AddOpcode(.lui)
			..AddOpcode(.addiu)
			..AddOpcode(.lw, .wild, .wild, 0x0)
			..AddOpcode(.lw, .wild, .wild, 0x4)
			..AddOpcode(.lui)
			..AddOpcode(.addi);

			signatureLocation = skyboxSignature.Find(this);

			if (!signatureLocation.IsNull) {
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				skyboxRegionsPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]) + 4;
			} else {
				// Spyro 1 Attempt
				skyboxSignature..Clear()
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.lui)
				..AddOpcode(.sw)
				..AddOpcode(.blez)
				..AddOpcode(.addu)
				..AddOpcode(.addiu)
				..AddOpcode(.lw)
				..AddOpcode(.addiu)
				..AddOpcode(.addu);
				
				signatureLocation = skyboxSignature.Find(this);
				ReadFromRAM(signatureLocation, &loadAddress, 8);
				skyboxRegionsPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}
		}
	}
}
