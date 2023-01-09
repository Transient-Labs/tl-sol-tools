// SPDX-License-Identifier: Apache-2.0

/// @title OwnableAccessControl.sol
/// @notice single owner, flexible access control mechanics
/// @dev can easily be extended by inheriting and applying additional roles
/// @dev by default, only the owner can grant roles but by inheriting, but you
///      may allow other roles to grant roles by using the internal helper.
/// @author transientlabs.xyz (https://github.com/Transient-Labs/tl-sol-tools)

/*
    ____        _ __    __   ____  _ ________                     __ 
   / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
  / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /__ 
/_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__(_)

*/

pragma solidity 0.8.17;

///////////////////// IMPORTS /////////////////////

import { Initializable } from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSetUpgradeable } from "openzeppelin-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { OwnableUpgradeable } from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

///////////////////// CUSTOM ERRORS /////////////////////

/// @dev does not have specified role
error NotSpecifiedRole(bytes32 role);

/// @dev is not specified role or owner
error NotRoleOrOwner(bytes32 role);

///////////////////// OWNABLE AUTH TL CONTRACT /////////////////////

abstract contract OwnableAccessControlUpgradeable is Initializable, OwnableUpgradeable {

    ///////////////////// STORAGE VARIABLES /////////////////////

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    mapping(bytes32 => mapping(address => bool)) private _roleStatus;
    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    ///////////////////// EVENTS /////////////////////

    event RoleChange(address indexed from, address indexed user, bool indexed approved, bytes32 role);

    ///////////////////// MODIFIERS /////////////////////

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert NotSpecifiedRole(role);
        }
        _;
    }

    modifier onlyRoleOrOwner(bytes32 role) {
        if (!hasRole(role, msg.sender) && owner() != msg.sender) {
            revert NotRoleOrOwner(role);
        }
        _;
    }

    ///////////////////// INITIALIZER /////////////////////

    function __OwnableAccessControl_init(address initOwner) internal onlyInitializing {
        __Ownable_init();
        _transferOwnership(initOwner);
        __OwnableAccessControl_init_unchained();
    }

    function __OwnableAccessControl_init_unchained() internal onlyInitializing {

    }

    ///////////////////// EXTERNAL FUNCTIONS /////////////////////

    /// @notice function to renounce role
    function renounceRole(bytes32 role) external {
        address[] memory members = new address[](1);
        members[0] = msg.sender;
        _setRole(role, members, false);
    }

    /// @notice function to grant/revoke a role to an address
    /// @dev requires owner to call this function but this may be further
    ///      extended using the internal helper function in inheriting contracts
    function setRole(bytes32 role, address[] memory roleMembers, bool status) external onlyOwner {
        _setRole(role, roleMembers, status);
    }

    /// @notice function to see if an address is the owner
    function hasRole(bytes32 role, address potentialRoleMember) public view returns(bool) {
        return _roleStatus[role][potentialRoleMember];
    }

    /// @notice function to get role members
    function getRoleMembers(bytes32 role) public view returns(address[] memory) {
        return _roleMembers[role].values();
    }

    ///////////////////// INTERNAL FUNCTIONS /////////////////////

    /// @notice helper function to set addresses for a role
    function _setRole(bytes32 role, address[] memory roleMembers, bool status) internal {
        for (uint256 i = 0; i < roleMembers.length; i++) {
            _roleStatus[role][roleMembers[i]] = status;
            if (status) {
                _roleMembers[role].add(roleMembers[i]);
            } else {
                _roleMembers[role].remove(roleMembers[i]);
            }
            emit RoleChange(msg.sender, roleMembers[i], status, role);
        }
    }

}