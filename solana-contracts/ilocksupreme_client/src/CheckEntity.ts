/****************************************************************
 * ILOCKsupreme client CheckEntity				*	
 ****************************************************************/

/****************************************************************
 * imports							*
 ****************************************************************/

// misc packages
const prompt = require("prompt-sync")({sigint: true});

// misc solana
import {
  	sendAndConfirmTransaction,
	Transaction,
	TransactionInstruction,
	SYSVAR_RENT_PUBKEY,
	SYSVAR_CLOCK_PUBKEY,
	SystemProgram,

} from "@solana/web3.js";

// utility functions
import {
	deriveAddress,
	establishConnection,
	establishOperator,
	checkProgram,
	toUTF8Array,
	createSeed,
	getUSERdata,
} from "./utils";

// utility constants
import {
	connection,
	ownerKEY,
	ilocksupremeID,
} from "./utils";

const BN = require("bn.js");

/****************************************************************
 * main								*
 ****************************************************************/

const CheckEntity = async () => {
	
	try {
	
	// setup
	await establishConnection();
	await establishOperator();
	await checkProgram();
	
	// get operator ID
	const programID = "InterlockSupremeAccount";

	// get ENTITY address
	const ENTITYhash = prompt("Please enter the ENTITY hash: ");

	// find GLOBAL address
	const [pdaGLOBAL, bumpGLOBAL] = await deriveAddress(toUTF8Array(programID));
	console.log(`. GLOBAL pda:\t\t${pdaGLOBAL.toBase58()} found after ${256 - bumpGLOBAL} tries`);

	// find ENTITY address
	const [pdaENTITY, bumpENTITY] = await deriveAddress(toUTF8Array(ENTITYhash));
	console.log(`. ENTITY pda:\t\t${pdaENTITY.toBase58()} found after ${256 - bumpENTITY} tries`);

	// setup instruction data
	const ixDATA = [9];

	// prepare transaction
	const CheckENTITYtx = new Transaction().add(
		new TransactionInstruction({
			keys: [
				{ pubkey: ownerKEY.publicKey, isSigner: true, isWritable: true, },
				{ pubkey: pdaGLOBAL, isSigner: false, isWritable: true, },
				{ pubkey: pdaENTITY, isSigner: false, isWritable: true, },
				{ pubkey: SYSVAR_CLOCK_PUBKEY, isSigner: false, isWritable: false, },
				{ pubkey: SystemProgram.programId, isSigner: false, isWritable: false, },
			],
			data: Buffer.from(new Uint8Array(ixDATA)),
			programId: ilocksupremeID,
		})
	);
		
	// send transaction
	console.log(`txhash: ${await sendAndConfirmTransaction(connection, CheckENTITYtx, [ownerKEY], )}`);
	
	// confirmation
	console.log(`\n* Successfully checked ENTITY '${ENTITYhash}'!\n`);

	} catch {

	console.log(Error);

	}
};

CheckEntity();

