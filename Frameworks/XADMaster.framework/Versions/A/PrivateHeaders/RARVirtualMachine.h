#ifndef __RARVIRTUALMACHINE_H__
#define __RARVIRTUALMACHINE_H__

#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <limits.h>

#define RARProgramMemorySize 0x40000
#define RARProgramMemoryMask (RARProgramMemorySize-1)
#define RARProgramWorkSize 0x3c000
#define RARProgramGlobalAddress RARProgramWorkSize
#define RARProgramGlobalSize 0x2000
#define RARProgramSystemGlobalSize 64
#define RARProgramUserGlobalSize (RARProgramGlobalSize-RARProgramSystemGlobalSize)

typedef struct RARVirtualMachine
{
	uint32_t registers[8];
	uint32_t flags;
	// TODO: align?
	uint8_t memory[RARProgramMemorySize+3]; // Let memory accesses at the end overflow.
	                                        // Possibly not 100% correct but unlikely to be a problem.
} RARVirtualMachine;

typedef uint32_t (*RARGetterFunction)(RARVirtualMachine *self,uint32_t value);
typedef void (*RARSetterFunction)(RARVirtualMachine *self,uint32_t value,uint32_t data);

typedef struct RAROpcode
{
	void *instructionlabel;

	RARGetterFunction operand1getter;
	RARSetterFunction operand1setter;
	uint32_t value1;

	RARGetterFunction operand2getter;
	RARSetterFunction operand2setter;
	uint32_t value2;

	uint8_t instruction;
	uint8_t bytemode;
	uint8_t addressingmode1;
	uint8_t addressingmode2;

	#if UINTPTR_MAX==UINT64_MAX
	uint8_t padding[12]; // 64-bit machine, pad to 64 bytes
	#endif
} RAROpcode;



// Setup

void InitializeRARVirtualMachine(RARVirtualMachine *self);

// Program building

void SetRAROpcodeInstruction(RAROpcode *opcode,unsigned int instruction,bool bytemode);
void SetRAROpcodeOperand1(RAROpcode *opcode,unsigned int addressingmode,uint32_t value);
void SetRAROpcodeOperand2(RAROpcode *opcode,unsigned int addressingmode,uint32_t value);
bool IsProgramTerminated(RAROpcode *opcodes,int numopcodes);
bool PrepareRAROpcodes(RAROpcode *opcodes,int numopcodes);

// Execution

bool ExecuteRARCode(RARVirtualMachine *self,RAROpcode *opcodes,int numopcodes);


// Instruction properties

int NumberOfRARInstructionOperands(unsigned int instruction);
bool RARInstructionHasByteMode(unsigned int instruction);
bool RARInstructionIsUnconditionalJump(unsigned int instruction);
bool RARInstructionIsRelativeJump(unsigned int instruction);
bool RARInstructionWritesFirstOperand(unsigned int instruction);
bool RARInstructionWritesSecondOperand(unsigned int instruction);

// Disassembling

char *DescribeRAROpcode(RAROpcode *opcode);
char *DescribeRARInstruction(RAROpcode *opcode);
char *DescribeRAROperand1(RAROpcode *opcode);
char *DescribeRAROperand2(RAROpcode *opcode);





static inline void SetRARVirtualMachineRegisters(RARVirtualMachine *self,uint32_t registers[8])
{
	memcpy(self->registers,registers,sizeof(self->registers));
}

static inline uint32_t _RARRead32(const uint8_t *b) { return ((uint32_t)b[3]<<24)|((uint32_t)b[2]<<16)|((uint32_t)b[1]<<8)|(uint32_t)b[0]; }

static inline void _RARWrite32(uint8_t *b,uint32_t n) { b[3]=(n>>24)&0xff; b[2]=(n>>16)&0xff; b[1]=(n>>8)&0xff; b[0]=n&0xff; }

static inline uint32_t RARVirtualMachineRead32(RARVirtualMachine *self,uint32_t address)
{
	return _RARRead32(&self->memory[address&RARProgramMemoryMask]);
}

static inline void RARVirtualMachineWrite32(RARVirtualMachine *self,uint32_t address,uint32_t val)
{
	_RARWrite32(&self->memory[address&RARProgramMemoryMask],val);
}

static inline uint32_t RARVirtualMachineRead8(RARVirtualMachine *self,uint32_t address)
{
	return self->memory[address&RARProgramMemoryMask];
}

static inline void RARVirtualMachineWrite8(RARVirtualMachine *self,uint32_t address,uint32_t val)
{
	self->memory[address&RARProgramMemoryMask]=val;
}

#define RARMovInstruction 0
#define RARCmpInstruction 1
#define RARAddInstruction 2
#define RARSubInstruction 3
#define RARJzInstruction 4
#define RARJnzInstruction 5
#define RARIncInstruction 6
#define RARDecInstruction 7
#define RARJmpInstruction 8
#define RARXorInstruction 9
#define RARAndInstruction 10
#define RAROrInstruction 11
#define RARTestInstruction 12
#define RARJsInstruction 13
#define RARJnsInstruction 14
#define RARJbInstruction 15
#define RARJbeInstruction 16
#define RARJaInstruction 17
#define RARJaeInstruction 18
#define RARPushInstruction 19
#define RARPopInstruction 20
#define RARCallInstruction 21
#define RARRetInstruction 22
#define RARNotInstruction 23
#define RARShlInstruction 24
#define RARShrInstruction 25
#define RARSarInstruction 26
#define RARNegInstruction 27
#define RARPushaInstruction 28
#define RARPopaInstruction 29
#define RARPushfInstruction 30
#define RARPopfInstruction 31
#define RARMovzxInstruction 32
#define RARMovsxInstruction 33
#define RARXchgInstruction 34
#define RARMulInstruction 35
#define RARDivInstruction 36
#define RARAdcInstruction 37
#define RARSbbInstruction 38
#define RARPrintInstruction 39
#define RARNumberOfInstructions 40

#define RARRegisterAddressingMode(n) (0+(n))
#define RARRegisterIndirectAddressingMode(n) (8+(n))
#define RARIndexedAbsoluteAddressingMode(n) (16+(n))
#define RARAbsoluteAddressingMode 24
#define RARImmediateAddressingMode 25
#define RARNumberOfAddressingModes 26

#endif
