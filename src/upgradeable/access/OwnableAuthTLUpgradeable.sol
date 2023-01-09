// SPDX-License-Identifier: Apache-2.0

/// @title OwnableAuthTLUpgradeable.sol
/// @notice abstract contract single owner with roles based access mechanics
/// @dev can easily be extended by inheriting and applying additional roles
/// @dev by default, only the owner can grant roles but by inheriting, you
///      may allow other roles to grant roles by using the internal helper.
/// @author transientlabs.xyz

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
import { OwnableTLUpgradeable } from "./OwnableTLUpgradeable.sol";

///////////////////// CUSTOM ERRORS /////////////////////

/// @dev does not have specified role
error NotSpecifiedRole(bytes32 role);

/// @dev is not specified role or owner
error NotRoleOrOwner(bytes32 role);

///////////////////// OWNABLE AUTH TL CONTRACT /////////////////////

abstract contract OwnableAuthTLUpgradeable is Initializable, OwnableTLUpgradeable {

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
        if (!hasRole(role, msg.sender) && getIfOwner(msg.sender)) {
            revert NotRoleOrOwner(role);
        }
        _;
    }

    ///////////////////// INITIALIZER /////////////////////

    function __OwnableAuthTLUpgradeable_init(address initOwner) internal onlyInitializing {
        __OwnableTLUpgradeable_init(initOwner);
        __OwnableAuthTLUpgradeable_init_unchained();
    }

    function __OwnableAuthTLUpgradeable_init_unchained() internal onlyInitializing {

    }

    ///////////////////// EXTERNAL FUNCTIONS /////////////////////

    /// @notice function to grant/revoke a role to an address
    /// @dev requires owner to call this function but this may be further
    ///      extended using the internal helper function in inheriting contracts
    function setRole(bytes32 role, address[] calldata roleMembers, bool status) external onlyOwner {
        _setRole(role, roleMembers, status);
    }

    /// @notice function to see if an address is the owner
    function hasRole(bytes32 role, address potentialRoleMember) public view returns(bool) {
        return _roleStatus[role][potentialRoleMember];
    }

    ///////////////////// INTERNAL FUNCTIONS /////////////////////

    /// @notice helper function to set addresses for a role
    function _setRole(bytes32 role, address[] calldata roleMembers, bool status) internal {
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

    ///////////////////// ERC-165 OVERRIDE /////////////////////

    /// @notice override ERC-165 implementation of this function
    /// @dev if using this contract with another contract that suppports ERC-165, will have to override in the inheriting contract
    function supportsInterface(bytes4 interfaceId) public view virtual override(OwnableTLUpgradeable) returns (bool) {
        return OwnableTLUpgradeable.supportsInterface(interfaceId);
    }
}