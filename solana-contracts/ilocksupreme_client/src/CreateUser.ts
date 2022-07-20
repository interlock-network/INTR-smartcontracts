/****************************************************************
 * ILOCKsupreme client CreateUser 				*	
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
} from "./utils";

// utility constants
import {
	connection,
	ownerKEY,
	ilocksupremeID,
} from "./utils";

/****************************************************************
 * main								*
 ****************************************************************/

const CreateUser = async () => {
	
	try {
	
	// setup
	await establishConnection();
	await establishOperator();
	await checkProgram();
	
	// get operator ID
	const programID = "InterlockSupremeAccount";

	// get vault address
	const ownerVault = prompt("Please enter your Ethereum vault address: ");

	// find GLOBAL address
	const [pdaGLOBAL, bumpGLOBAL] = await deriveAddress(toUTF8Array(programID));
	console.log(`. New GLOBAL pda:\t\t${pdaGLOBAL.toBase58()} found after ${256 - bumpGLOBAL} tries`);

	// find USER address
	const [pdaUSER, bumpUSER] = await deriveAddress(toUTF8Array(ownerVault));
	console.log(`. New USER pda:\t\t${pdaUSER.toBase58()} found after ${256 - bumpUSER} tries`);
	
	// setup instruction data
	const ixDATA = [2, bumpUSER]
		.concat(toUTF8Array(ownerVault));

	// prepare transaction
	const CreateUSERtx = new Transaction().add(
		new TransactionInstruction({
			keys: [
				{ pubkey: ownerKEY.publicKey, isSigner: true, isWritable: true, },
				{ pubkey: pdaGLOBAL, isSigner: false, isWritable: true, },
				{ pubkey: pdaUSER, isSigner: false, isWritable: true, },
				{ pubkey: SYSVAR_RENT_PUBKEY, isSigner: false, isWritable: false, },
				{ pubkey: SystemProgram.programId, isSigner: false, isWritable: false, },
			],
			data: Buffer.from(new Uint8Array(ixDATA)),
			programId: ilocksupremeID,
		})
	);
		
	// send transaction
	console.log(`txhash: ${await sendAndConfirmTransaction(connection, CreateUSERtx, [ownerKEY], )}`);
	
	// confirmation
	console.log(`\n* Successfully created new USER account for '${programID}'!\n`);

	} catch {

	console.log(Error);

	}
};

CreateUser();
