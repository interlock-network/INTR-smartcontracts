/****************************************************************
 * ILOCKsupreme Solana Contract
 ****************************************************************/

#![allow(non_snake_case)]
use solana_program::{
        account_info::{
            next_account_info,
            AccountInfo
        },
        clock::Clock,
        entrypoint::ProgramResult,
        program_error::ProgramError,
        program_pack::Pack,
        pubkey::Pubkey,
        sysvar::Sysvar,
    };


use crate::{
        processor::run::Processor,
        utils::utils::*,
        error::error::ContractError::*,
        state::{
            GLOBAL::*,
            ENTITY::*,
        },
    };

// for this instruction, the expected accounts are:

impl Processor {

    pub fn process_check_entity(
        _program_id: &Pubkey,
        accounts: &[AccountInfo],
    ) -> ProgramResult {

        // it is customary to iterate through accounts like so
        let account_info_iter = &mut accounts.iter();
        let owner = next_account_info(account_info_iter)?;
        let pdaGLOBAL = next_account_info(account_info_iter)?;
        let pdaENTITY = next_account_info(account_info_iter)?;
        let clock = next_account_info(account_info_iter)?;

        // check to make sure tx sender is signer
        if !owner.is_signer {
            return Err(ProgramError::MissingRequiredSignature);
        }

        // get GLOBAL data
        let GLOBALinfo = GLOBAL::unpack_unchecked(&pdaGLOBAL.try_borrow_data()?)?;

        // check that owner is *actually* owner
        if GLOBALinfo.owner != *owner.key {
            return Err(OwnerImposterError.into());
        }

        // get user account info
        let mut ENTITYinfo = ENTITY::unpack_unchecked(&pdaENTITY.try_borrow_data()?)?;

        // unpack ENTITY flags
        let mut ENTITYflags = unpack_16_flags(ENTITYinfo.flags);

        // make sure ENTITY is not settling
        if ENTITYflags[7] {
            return Err(EntitySettlingError.into());
        }

        // make sure ENTITY is not settled
        if ENTITYflags[6] {
            return Err(EntitySettledError.into());
        }

        // get current time
        let timestamp = Clock::from_account_info(&clock)?.unix_timestamp;
        
        // computer time delta
        let timedelta = timestamp - ENTITYinfo.timestamp;


        // is delta over threshold?
        if timedelta as u32 > GLOBALinfo.values[2] {

            // set threshold-passed flag
            ENTITYflags.set(4, true);
            ENTITYflags.set(7, true);
            
            // repack
            ENTITYinfo.flags = pack_16_flags(ENTITYflags);
            ENTITY::pack(ENTITYinfo, &mut pdaENTITY.try_borrow_mut_data()?)?;

            return Ok(())
        }

        Ok(())
    }
}
