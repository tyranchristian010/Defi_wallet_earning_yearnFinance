pragma solidity ^0.6.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';    //imported because we need it to create our contract pointers to DAI and yDAI.
interface IYDAI {                                           //imported because we need to interact with the yearn version yDai. We get this info from their github. https://github.com/iearn-finance/itoken/blob/master/contracts/YDAIv3.sol
 function deposit(uint _amount) external;                   //the deposit function signature from yearn allows us to invest tokens into t heir smart contract.
 function withdraw(uint _shares) external;                  //the waithdraw function signature from yearn allows us to remove our tokens from their smart contract.
 function balanceOf(address account)external view returns(uint);  //keeps track of our balance also from yearn finace yDAIv3.sol
 function getPricePerFullShare() external view returns (uint);     
}

contract Wallet {
address admin;
IERC20 dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);  //activate the IERC20 dai pointer by passing it the dai contract address 
IYDAI yDai = IYDAI(0xC2cB1040220768554cf699b0d863A3cd4324ce32);    //activate the IYDAI yDai pointer by passing it the yDai contract address from the yearn finance registry. 
                                                                    //now we are able to interact with DAI and yDai
constructor() public {
    admin = msg.sender;                                      //makes the admin the only one who can spend tokens
}

function save(uint amount) external {                       //this function is passed an amount to "save" which will deposit the amount into the yearn v3 contract.
    dai.transferFrom(msg.sender, address(this), amount);    //transfers the dai from the msg.sender to our Wallet.sol contract. When you call the save() function, you need to approve your tokens to be spent by the wallet and i think you do that in the 2_deploy_contracts.js.
    dai.approve(address(yDai), amount);                     //then we send our Dai to the yDai contract. But first we need to approve yDai as a spender. the Dai is in our wallet at this time and yDai will try to use the transferFrom() but it must be approved.
    yDai.deposit(amount);                                           //now we use the yDai pointer and call the deposit() for this amount. Now the Dai token are inside yDai.sol and earning interest. In return we receive yDai tokens

}
function spend(uint amount, address recipient) external {    //this function is passed an amount to spend/withdraw from the yDai smart contract and the recipient address.
    require(msg.sender==admin, 'only admin');                  //we must require that the only person who can spend/withdraw our tokens is the admin/msg.sender
    uint balanceShares = yDai.balanceOf(address(this));        //when we withdraw our Dai we have to remember that the yDai withdraw function expects an amount in yDai. so this function tells us the balance in yDai.
    yDai.withdraw(balanceShares);                             //yDai.sol only knows the balance of our Wallet.sol address. so this withdraws everything. Now all the Dai are in the wallet so we can spend them.
    dai.transfer(recipient, amount);                         //here we spend by sending the amount to the recipient address. Any remaining balance will be re invested into yearn.finance
    uint balanceDai = dai.balanceOf(address(this));           //this is the balance of Dai after we have spent the amount. We will reinvest balanceDai back into the yearn finance contract
    dai.approve(address(yDai), balanceDai);                     //then we send our Dai to the yDai contract. But first we need to approve yDai as a spender. the Dai is in our wallet at this time and yDai will try to use the transferFrom() but it must be approved.
    yDai.deposit(balanceDai);
}
function balance() external view returns(uint) {
    uint price = yDai.getPricePerFullShare();               //to get the balance of your wallet first you need the price of yDai per full share.
    uint balanceShares = yDai.balanceOf(address(this));     //you also need to know your personal balance of shares.
    return balanceShares*price;                             //now you know your total balance in your wallet.sol contract.
}
}
