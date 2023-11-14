// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {RoboNFT} from "../src/RoboNFT.sol";

contract RoboNFTScript is Script {
    function setUp() public {}

    function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address account = vm.addr(privateKey);
        console2.log("Account", account);
        vm.startBroadcast(privateKey);
        //這裡部署
        RoboNFT nft = new RoboNFT();
        vm.stopBroadcast();
        console2.log(address(nft));
    }
}