/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
// SPDX-License-Identifier: MIT
//
// Interlock ERC-20 ILOCK Token Mint Platform
//
// Contributors:
// blairmunroakusa
// ...
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

 /** derived from from oz:
 * functions should revert instead returning `false` on failure.
 * This behavior is nonetheless conventional and does not conflict
 * with the expectations of ERC20 applications.
 *
 * An {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events.
 **/

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "./ILOCKpool.sol";
import "../../proxy/utils/Initializable.sol";
//import “https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol”;

contract ERC20ILOCKUpgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* declarations
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

	/** @dev **/

		// issued upon reward distribution to interlocker
    	event Reward(address indexed interlocker, uint256 amount );

		// Constants (order doesn't matter for storage)
	string constant private _NAME = "Interlock Network";
	string constant private _SYMBOL = "ILOCK";
	uint8 constant private _DECIMALS = 18;
	uint256 constant private _DECIMAL_MAGNITUDE = 10 ** _DECIMALS;
	uint256 constant private _CAP = 1_000_000_000;
	uint8 constant private _POOLCOUNT = 10;
	uint256 constant private _MONTH = 30 days;
	
	uint256 private _totalSupply;
	uint256 private _nextPayout;
	uint256 private _rewardedTotal;

	address private _owner;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	mapping(address => uint256) private _rewardedInterlocker;
	mapping(address => mapping(bytes32 => Stake)) private _stakes;
	mapping(address => bytes32[]) private _stakeIdentifiers;

	address[] public pools;
	bool public TGEtriggered;
	uint256 public monthsPassed;

	struct Stake {
	    uint256 paid;
	    uint256 share;
	    uint8 pool; }

	struct PoolData {
	    uint256 tokens;
	    uint256 vests;
	    uint256 cliff;
	    string name; }

	PoolData[_POOLCOUNT] public pool;

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* init
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

		 // owned by msg.sender
		// initializes contract
	function initialize(
	) public initializer {

		_owner = _msgSender();

		_initializePools();

		uint256 sumTokens;
		// iterate through pools to create struct array
		for (uint8 i = 0; i < _POOLCOUNT; i++) {

			// here we are adding up tokens to make sure sum is correct
			sumTokens += pool[i].tokens;

			// in the same breath we convert token amounts to ERC20 format
			pool[i].tokens *= _DECIMAL_MAGNITUDE;
		}

		require(
			sumTokens == _CAP,
			"pool token amounts must add up cap");

		_totalSupply = 0;
		TGEtriggered = false; }

/*************************************************/

	function _initializePools(
	) internal {
		
		pool[0] = PoolData({
			tokens: 3_703_704,
			vests: 3,
			cliff: 1,
			name: "community sale"
		});
		pool[1] = PoolData({
			tokens: 48_626_667,
			vests: 18,
			cliff: 1,
			name: "presale 1"
		});
		pool[2] = PoolData({
			tokens: 33_333_333,
			vests: 15,
			cliff: 1,
			name: "presale 2"
		});
		pool[3] = PoolData({
			tokens: 25_714_286,
			vests: 12,
			cliff: 1,
			name: "presale 3"
		});
		pool[4] = PoolData({
			tokens: 28_500_000,
			vests: 3,
			cliff: 0,
			name: "public sale"
		});
		pool[5] = PoolData({
			tokens: 200_000_000,
			vests: 36,
			cliff: 6,
			name: "founders and team"
		});
		pool[6] = PoolData({
			tokens: 40_000_000,
			vests: 24,
			cliff: 1,
			name: "outlier ventures"
		});
		pool[7] = PoolData({
			tokens: 25_000_000,
			vests: 24,
			cliff: 1,
			name: "advisors"
		});
		pool[8] = PoolData({
			tokens: 258_122_011,
			vests: 84,
			cliff: 0,
			name: "foundation"
		});
		pool[9] = PoolData({
			tokens: 37_000_000,
			vests: 12,
			cliff: 1,
			name: "strategic partners and KOL"
		}); }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* modifiers
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

		// only allows owner to call
	modifier onlyOwner(
	) {
		require(
			_msgSender() == _owner,
			"only owner can call"
		);
		_; }

/*************************************************/

		// verifies zero address was not provied
	modifier noZero(
		address _address
	) {
		require(
			_address != address(0),
			"zero address where it shouldn't be"
		);
		_; }

/*************************************************/

		// verifies there exists enough token to proceed
	modifier isEnough(
		uint256 _available,
		uint256 _amount
	) {
		require(
            		_available >= _amount,
			"not enough tokens available"
		);
		_; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* TGE
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

		// generates all the tokens
	function triggerTGE(
	) public onlyOwner {

		require(
			TGEtriggered == false,
			"TGE already happened");

		// create pool accounts and initiate
		for (uint8 i = 0; i < _POOLCOUNT; i++) {
			
			// generate pools and mint to
			address Pool = address(new ILOCKpool());
			pools.push(Pool);
			uint256 balance = pool[i].tokens;
			_balances[Pool] = balance;

			emit Transfer(
				address(0),
				Pool,
				balance);
			}

		// start the clock for time vault pools
		_nextPayout = block.timestamp + 30 days;
		monthsPassed = 0;

		// approve owner to spend any tokens sent to this contract in future
		_approve(
			address(this),
			_msgSender(),
			_CAP * _DECIMAL_MAGNITUDE);


		// this must never happen again...
		TGEtriggered = true; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* ownership methods
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/					
		// changes the contract owner
	function changeOwner(
		address newOwner
	) public onlyOwner {

		// reassign
		_owner = newOwner;
	}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* ERC20 getter methods
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

		// gets token name (Interlock Network)
	function name(
	) public pure override returns (string memory) {

		return _NAME; }

/*************************************************/

		// gets token symbol (ILOCK)
	function symbol(
	) public pure override returns (string memory) {

		return _SYMBOL; }

/*************************************************/

		// gets token decimal number
	function decimals(
	) public pure override returns (uint8) {

		return _DECIMALS; }

/*************************************************/

		// gets tokens minted
	function totalSupply(
	) public view override returns (uint256) {

		return _totalSupply; }

/*************************************************/

		// gets account balance (tokens payable)
	function balanceOf(
		address account
	) public view override returns (uint256) {

		return _balances[account]; }

/*************************************************/

		// gets tokens spendable by spender from owner
	function allowance(
		address owner,
		address spender
	) public view virtual override returns (uint256) {

		return _allowances[owner][spender]; }

/*************************************************/

		// gets total tokens remaining in pools
	function reserve(
	) public view returns (uint256) {

		return _CAP * _DECIMAL_MAGNITUDE - _totalSupply; }

/*************************************************/

		// gets token cap
	function cap(
	) public pure returns (uint256) {

		return _CAP; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* ERC20 doer methods
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

		   // emitting Transfer, reverting on failure
		  // where caller balanceOf must be >= amount
		 // where `to` cannot = zero  address
		// increases spender allowance
	function transfer(
		address to,
		uint256 amount
	) public virtual override returns (bool) {
		address owner = _msgSender();

		_transfer(owner, to, amount);

		return true; }

/*************************************************/

		     // emitting Approval, reverting on failure
		    // where msg.sender allowance w/`from` must be >= amount
		   // where `from` balance must be >= amount
		  // where `from` and `to` cannot = zero address
		 // which does not update allowance if allowance = u256.max
		// pays portion of spender's allowance with owner to recipient
	function transferFrom(
		address from,
		address to,
		uint256 amount
	) public virtual override returns (bool) {
		address spender = _msgSender();		

		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true; }

/*************************************************/

		// internal implementation of transfer() above
	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal virtual noZero(from) noZero(to) isEnough(_balances[from], amount) returns (bool) {
		_beforeTokenTransfer(from, to, amount);

		uint256 fromBalance = _balances[from];
		unchecked {
			_balances[from] = fromBalance - amount;
			_balances[to] += amount; }

		emit Transfer(from, to, amount);

		_afterTokenTransfer(from, to, amount);
		
		return true; }

/*************************************************/

		  // emitting Approval, reverting on failure
		 // (=> no allownance delta when TransferFrom)
		// defines tokens available to spender from msg.sender
	function approve(
		address spender,
		uint256 amount
	) public virtual override returns (bool) {

		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true; }

/*************************************************/

		// internal implementation of approve() above 
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual noZero(owner) noZero(spender) {

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount); }

/*************************************************/

		   // emitting Approval if finite, reverting on failure 
		  // will do nothing if infinite allowance
		 // used strictly internally
		// deducts from spender's allowance with owner
	function _spendAllowance(
		address owner,
		address spender,
		uint256 amount
	) internal virtual isEnough(allowance(owner, spender), amount) {
	
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			unchecked {
				_approve(owner, spender, currentAllowance - amount);} } }

/*************************************************/

		  // emitting Approval, reverting on failure
		 // (=> no allownance delta when TransferFrom)
		// defines tokens available to spender from msg.sender
	function approvePool(
		address spender,
		uint256 amount,
		uint8 poolnumber
	) public onlyOwner returns (bool) {

		_approve(pools[poolnumber], spender, amount);

		return true; }

/*************************************************/

		// allows client to safely execute approval facing double spend attack
	function increaseAllowance(
		address spender,
		uint256 addedValue
	) public virtual returns (bool) {
        
		address owner = _msgSender();
        	_approve(owner, spender, allowance(owner, spender) + addedValue);
        
		return true; }

/*************************************************/

		// allows client to safely execute approval facing double spend attack
	function decreaseAllowance(
		address spender,
		uint256 subtractedValue
	) public virtual returns (bool) {

        	address owner = _msgSender();
        	uint256 currentAllowance = allowance(owner, spender);
        	require(
			currentAllowance >= subtractedValue,
			"ERC20: decreased allowance below zero");

        	unchecked {
			_approve(owner, spender, currentAllowance - subtractedValue);}

		 return true; }

/*************************************************/

		    // where `from` && `to` != zero account => to be regular xfer
		   // where `from` = zero account => `amount` to be minted `to`
		  // where `to` = zero account => `amount` to be burned `from`
		 // where `from` && `to` = zero account => impossible
		// hook that inserts behavior prior to transfer/mint/burn
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}

/*************************************************/

		    // where `from` && `to` != zero account => was regular xfer
		   // where `from` = zero account => `amount` was minted `to`
		  // where `to` = zero account => `amount` was burned `from`
		 // where `from` && `to` = zero account => impossible
		// hook that inserts behavior prior to transfer/mint/burn
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* stakeholder entry and distribution
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

		// makes sure that distributions do not happen too early
	function _checkTime(
	) internal returns (bool) {

		// test time
		if (block.timestamp > _nextPayout) {
			
			uint256 deltaT = block.timestamp - _nextPayout;
			uint256 months = deltaT / 30 days + 1;
			_nextPayout += _nextPayout + months * 30 days;
			monthsPassed += months;
			return true;
		}

		// not ready
		return false;
	}

/*************************************************/

		// register stakeholder
	function registerStake(
		address stakeholder,
		Stake calldata data
	) public noZero(stakeholder) onlyOwner returns (bool) {

		bytes32 identifier = keccak256(
							 bytes.concat(bytes20(stakeholder),
							 			  bytes32(data.share),
										  bytes1(data.pool) ));

		// validate input
		require(
			!stakeExists(stakeholder, identifier),
			"this stake already exists and cannot be edited");
		require(
			data.paid == 0,
			"amount paid must be zero");
		require(
			data.share >= pool[data.pool].vests,
			"share is too small");
		require(
			data.pool < _POOLCOUNT,
			"invalid pool number");

		// store stake
		_stakes[stakeholder][identifier] = data;

		// store identifier for future iteration
		_stakeIdentifiers[stakeholder].push(identifier);

		return true; }

/*************************************************/

		// claim stake for vest periods accumulated
	function claimStake(
		bytes32 stakeIdentifier
	) public returns (bool) {

		// see if we need to update time
		_checkTime();

		// caller must own the stake they are claiming
		require(
			stakeExists(_msgSender(), stakeIdentifier),
			"this stake does not exist and cannot be claimed");

		Stake storage stake = _stakes[_msgSender()][stakeIdentifier];
		uint256 cliff = pool[stake.pool].cliff;
		uint256 vests = pool[stake.pool].vests;

		// make sure cliff has been surpassed
		require(
			monthsPassed >= cliff,
			"too soon -- cliff not yet passed");

		// number of payouts must not surpass number of vests
		require(
			stake.paid < stake.share,
			"member already collected entire token share");
		
		// determine the traunch amount claimant has rights to for each vested month
		uint256 payout = stake.share / uint256(vests);

		// and determine the number of payments claimant has received
		uint256 payments = uint8(stake.paid / payout);

		// even if cliff is passed, is it too soon for next payment?
		require(
			payments < monthsPassed,
			"payout too early");
		
		uint256 thesePayments;

		// when time has past vesting period, pay out remaining unclaimed payments
		if (cliff + vests <= monthsPassed) {
			
			thesePayments = vests - payments;

		// don't count months past vests+cliff as payments
		} else {

			thesePayments = 1 + monthsPassed - payments - cliff;
		}
		// use payments to calculate amount to pay out
		uint256 thisPayout = thesePayments * payout;

		// if at final payment, add remainder of share to final payment
		if (stake.share - stake.paid - thisPayout < stake.share / vests) {
			
			thisPayout += stake.share % vests;
		}

		// transfer and make sure it succeeds
		require(
			_transfer(pools[stake.pool], _msgSender(), thisPayout),
			"stake claim transfer failed");

		// update member state
		_stakes[_msgSender()][stakeIdentifier].paid += thisPayout;

		// update total supply and reserve
		_totalSupply += thisPayout;
		
		return true; }	

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
	/**
	* stakeholder getters
	**/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

		    // get how much of amount left to pay is available to claim
		   // get amount left to pay
		  // get amount paid so far to member
		 // get amount investor still needs to pay in before claiming tokens
		// get time remaining until next payout ready
	function stakeStatus(
		bytes32 stakeIdentifier
	) public view returns (
		uint256 timeLeft,
		uint256 share,
		uint256 paidOut,
		uint256 payRemaining,
		uint256 payAvailable,
		uint256 vestingMonths,
		uint256 monthsRemaining,
		uint256 cliff
	) {

		// caller must own the stake they are viewing
		require(
			stakeExists(_msgSender(), stakeIdentifier),
			"this stake does not exist and cannot be viewed");

		Stake memory stake = _stakes[_msgSender()][stakeIdentifier];
		cliff = pool[stake.pool].cliff;
		uint256 vests = pool[stake.pool].vests;

		// compute the time left until the next payment is available
		// if months passed beyond last payment, stop counting
		if (monthsPassed >= vests + cliff) {
			
			timeLeft = 0;

		// when cliff hasn't been surpassed, include that time into countdown
		} else if (monthsPassed < cliff) {
			
			timeLeft = (cliff - monthsPassed - 1) * 30 days +
				    _nextPayout - block.timestamp;

		// during vesting period, timeleft is only time til next month's payment
		} else {

			timeLeft = _nextPayout - block.timestamp;
		}

		// how much has member already claimed
		paidOut = stake.paid;

		// determine the number of payments claimant has rights to
		uint256 payout = stake.share / vests;

		// and determine the number of payments claimant has received
		uint256 payments = paidOut / payout;

		// how much does member have yet to collect, after vesting complete
		payRemaining = stake.share - paidOut;

		// compute the pay available to claim at current moment
		// if months passed are inbetween cliff and end of vesting period
		if (monthsPassed >= cliff && monthsPassed < cliff + vests) {
			
			payAvailable = (1 + monthsPassed - cliff - payments) * payout;

		// until time reaches cliff, no pay is available
		} else if (monthsPassed < cliff ){

			payAvailable = 0;

		// if time has passed cliff and vesting period, the entire remaining share is available
		} else {

			payAvailable = stake.share - paidOut;
		}

		// if at final payment, add remainder of share to final payment
		if (stake.share - paidOut - payAvailable < payout && payAvailable > 0) {
			
			payAvailable += stake.share % vests;
		}

		return (
			timeLeft,
			stake.share,
			paidOut,
			payRemaining,
			payAvailable,
			vests,
			cliff,
			vests - cliff - monthsPassed
		); }

/*************************************************/

		// gets stake identifiers for stakes owned by message caller
	function getStakeIdentifiers(
		address stakeholder
	) public view returns (bytes32[] memory stakeIdentifiers) {

		return _stakeIdentifiers[stakeholder]; }
    
/*************************************************/

		 // that ensures we do not overwrite
		// helper view function for validating registerStake input (stake existence)
	function stakeExists(
		address stakeholder,
		bytes32 identifier
	) public view returns (bool) {
    
		for (uint16 i = 0; i < _stakeIdentifiers[stakeholder].length; i++) {

       		if (_stakeIdentifiers[stakeholder][i] == identifier) {

        		return true; } }

    	return false; }

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/


	function testingIncrementMonth(
	) public returns (uint256) {

		monthsPassed += 1;
		_nextPayout += _MONTH;

		return monthsPassed; }






	uint256[100] private __gap;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/


