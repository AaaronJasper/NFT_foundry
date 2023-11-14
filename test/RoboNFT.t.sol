// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {RoboNFT} from "../src/RoboNFT.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RoboNFTTest is Test {
    RoboNFT public roboNFT;
    address public sender;

    receive() external payable {}

    //測試前準備
    function setUp() public {
        roboNFT = new RoboNFT();
        roboNFT.setNotRevealedURI(
            "ipfs://QmRjP2kYNprhM3Tsa4bA3urAneuQPggUZjxG9R5iZyA2tR"
        );
        roboNFT.setBaseTokenUri(
            "ipfs://Qme2NsRZQnDh95VaLfeNriSuKbQut7uGq76tD8BY1HusPx/"
        );
        //建立signer
        sender = vm.addr(
            0x092c77d2f39f7a9452c5731e353e143f07c6aa8e2e895f2d76c252426a76f563
        );
        deal(address(this), 100 ether);
    }

    //測試基本資料
    //invariant測試基本資料
    function invariant_basic_information() public {
        assertEq(roboNFT.mintPrice(), 0.02 ether);
        assertEq(roboNFT.maxSupply(), 12);
        assertEq(roboNFT.maxPerWallet(), 3);
        assertEq(roboNFT.owner(), address(this));
        assertEq(roboNFT.isPublicMintEnabled(), false);
        assertEq(roboNFT.isFlipRevealed(), false);
    }

    //開啟鑄造
    function test_enable_mint() public {
        roboNFT.setIsPublicMintEnabled();
        assertTrue(roboNFT.isPublicMintEnabled());
    }

    //鑄造及開啟盲盒
    function test_mint() public {
        roboNFT.setIsPublicMintEnabled();
        hoax(sender, 1 ether);
        roboNFT.mint{value: 0.02 ether}(1);
        assertEq(roboNFT.walletMints(sender), 1);
        assertEq(roboNFT.ownerOf(1), address(sender));
        assertEq(
            roboNFT.tokenURI(1),
            "ipfs://QmRjP2kYNprhM3Tsa4bA3urAneuQPggUZjxG9R5iZyA2tR"
        );
        roboNFT.setFlipReveal();
        assertTrue(roboNFT.isFlipRevealed());
        assertEq(
            roboNFT.tokenURI(1),
            "ipfs://Qme2NsRZQnDh95VaLfeNriSuKbQut7uGq76tD8BY1HusPx/1.json"
        );
    }

    //確認餘額及提款
    function test_withdraw() public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        hoax(sender, 1 ether);
        roboNFT.mint{value: 0.02 ether}(1);
        assertEq(address(roboNFT).balance, 0.02 ether);
        //提款
        roboNFT.withdraw();
        assertEq(address(roboNFT).balance, 0);
        assertEq(address(this).balance, 100.02 ether);
    }

    //未開放前鑄造
    function test_not_enabled_mint() public {
        //鑄造一個NFT
        hoax(sender, 1 ether);
        vm.expectRevert(bytes("minting not enabled"));
        roboNFT.mint{value: 0.02 ether}(1);
    }

    //錯誤的金額
    function test_wrong_price_to_mint() public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        hoax(sender, 1 ether);
        vm.expectRevert(bytes("wrong mint value"));
        roboNFT.mint{value: 0.03 ether}(1);
    }

    //超出購買限制
    function test_out_of_amount_to_mint() public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        hoax(sender, 1 ether);
        vm.expectRevert(bytes("exceed max wallet"));
        roboNFT.mint{value: 0.08 ether}(4);
    }

    //查詢不存在的NFT id
    function test_not_exist_token() public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        hoax(sender, 1 ether);
        roboNFT.mint{value: 0.02 ether}(1);
        vm.expectRevert(bytes("Token does not exist!"));
        roboNFT.tokenURI(2);
    }

    //超出擁有數量
    function test_out_of_ownable_token() public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        deal(sender, 1 ether);
        vm.startPrank(sender);
        roboNFT.mint{value: 0.06 ether}(3);
        vm.expectRevert(bytes("exceed max wallet"));
        roboNFT.mint{value: 0.06 ether}(3);
        vm.stopPrank();
    }

    //已完售
    function test_soldout() public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        hoax(address(1), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(2), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(3), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(4), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(sender, 1 ether);
        vm.expectRevert(bytes("sold out"));
        roboNFT.mint{value: 0.02 ether}(1);
    }

    //非擁有者提款
    function testFail_not_owner_withdraw() public {
        vm.prank(sender);
        //提款
        roboNFT.withdraw();
    }

    //全部發售完確認總數量
    function test_soldout_amount() public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        hoax(address(1), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(2), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(3), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(4), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(sender, 1 ether);
        assertEq(roboNFT.totalSupply(), 12);
    }

    //確認全部發售完其對應號碼
    function test_soldout_and_token_number(uint num) public {
        roboNFT.setIsPublicMintEnabled();
        //鑄造一個NFT
        hoax(address(1), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(2), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(3), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(address(4), 1 ether);
        roboNFT.mint{value: 0.06 ether}(3);
        hoax(sender, 1 ether);
        assertEq(roboNFT.totalSupply(), 12);
        //限制其號碼
        vm.assume(num > 0 && num <= 12);
        assertEq(
            roboNFT.tokenURI(num),
            "ipfs://QmRjP2kYNprhM3Tsa4bA3urAneuQPggUZjxG9R5iZyA2tR"
        );
        roboNFT.setFlipReveal();
        assertEq(
            roboNFT.tokenURI(num),
            string(
                abi.encodePacked(
                    "ipfs://Qme2NsRZQnDh95VaLfeNriSuKbQut7uGq76tD8BY1HusPx/",
                    Strings.toString(num),
                    ".json"
                )
            )
        );
    }
}
