// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////
/// This program is free software: you can redistribute it and/or modify    ///
/// it under the terms of the MIT Public License.                           ///
///                                                                         ///
/// This is a Proof Of Concept and is not intended for production use.      ///
/// Tests are incomplete and it contracts have not been audited.            ///
///                                                                         ///
/// It is distributed in the hope that it will be useful and insightful,    ///
/// but WITHOUT ANY WARRANTY; without even the implied warranty of          ///
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    ///
///////////////////////////////////////////////////////////////////////////////

/// @title Deploy script Managed Grants
/// @notice Managed Grants is a DAO example that implements a grant management system with multiple roles and checks and balances.
/// 
/// This example implements:
/// Executive laws: 
/// - A law to start grants: BespokeAction, access role = delegates. By majority vote.
/// - A law to stop grants: BespokeAction, access role = delegates. By majority vote.
/// - A law that allows community members to request tokens from a specific grant law, access role = members.
/// - A law that allows allocators to assign tokens to a grant request. Access role = allocator.
/// - A law to challenge a decision by allocators. Access role = members.
/// - A law to revert a decision by allocators. Can only react to a challenge from a public account. Access role = judge.
///
/// Electoral laws: (possible roles: allocator, judge, community member, delegate)
/// - a law to self select as community member. Access role: public.
/// - a law to nominate oneself for a judge role. Access role: public.
/// - a law to assign a judge role to a nominated account. Access role: delegate, using majority vote.
/// - a law to remove a judge. Access role: delegate, using majority vote.
/// - a law to nominate oneself for a delegate role. Access role: public.
/// - a law to assign a delegate role to a nominated account. Access role: delegate, using delegate election vote.
/// - a law to nominate oneself for an allocator role. Access role: public.
/// - a law to assign or revoke allocator role to a nominated account. Access role: delegate, using majority vote.

/// @author 7Cedars

pragma solidity 0.8.26;


