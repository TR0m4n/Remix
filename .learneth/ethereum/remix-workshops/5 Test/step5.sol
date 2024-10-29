pragma solidity ^0.5.1;

pragma solidity ^0.5.1;

contract LogicContract {
    function getNumber() public pure returns (uint) {
        return 10;
    }
}

contract ProxyContract {
    address internal proxied;
    
   constructor (address _proxied) public {
        proxied = _proxied;
    }
}