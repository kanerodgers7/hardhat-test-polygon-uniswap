// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./TestUtils.sol";

contract TestUtilsTest is Test, TestUtils {
    function testNearestUsableTick() public {
        if (nearestUsableTick(85176, 60) != 85200)
            setFailedStatus(true, "NearestUsableTick1");
        if (nearestUsableTick(85170, 60) != 85200)
            setFailedStatus(true, "NearestUsableTick2");
        if (nearestUsableTick(85169, 60) != 85140)
            setFailedStatus(true, "NearestUsableTick3");
        if (nearestUsableTick(85200, 60) != 85200)
            setFailedStatus(true, "NearestUsableTick4");
        if (nearestUsableTick(85140, 60) != 85140)
            setFailedStatus(true, "NearestUsableTick5");
        // assertEq(nearestUsableTick(85176, 60), 85200);
        // assertEq(nearestUsableTick(85170, 60), 85200);
        // assertEq(nearestUsableTick(85169, 60), 85140);
        // assertEq(nearestUsableTick(85200, 60), 85200);
        // assertEq(nearestUsableTick(85140, 60), 85140);
    }

    function testTick60() public {
        if (tick60(5000) != 85200) setFailedStatus(true, "tick60_1");
        if (tick60(4545) != 84240) setFailedStatus(true, "tick60_2");
        if (tick60(6250) != 87420) setFailedStatus(true, "tick60_3");
        // assertEq(tick60(5000), 85200);
        // assertEq(tick60(4545), 84240);
        // assertEq(tick60(6250), 87420);
    }

    function testSqrtP60() public {
        if (sqrtP60(5000) != 5608950122784459951015918491039)
            setFailedStatus(true, "sqrtP60_1");
        if (sqrtP60(4545) != 5346092701810166522520541901099)
            setFailedStatus(true, "sqrtP60_2");
        if (sqrtP60(6250) != 6267377518277060417829549285552)
            setFailedStatus(true, "sqrtP60_3");
        // assertEq(sqrtP60(5000), 5608950122784459951015918491039);
        // assertEq(sqrtP60(4545), 5346092701810166522520541901099);
        // assertEq(sqrtP60(6250), 6267377518277060417829549285552);
    }
}
