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

/// @title Deploy script Governed Upgrades
/// @notice Governed Upgrades is a simple example of a DAO. It acts as an introductory example of governed upgrades using the Powers protocol. 
/// 
/// This example needs: (use AI to generate the laws)
/// Executive laws: 
/// - A law to adopt or revoke a law. Access role = previous DAO 
/// - A law to veto adopt or revoke a law. Access role = delegates
/// - A preset law to Exchange tokens at uniswap or sth similar chain. Access role = delegates
/// - A preset law to to veto Exchange tokens at uniswap or sth similar chain veto. Access role = previous DAO.

/// Electoral laws: (possible roles: previous DAO, delegates)
/// - a law to nominate oneself for a delegate role. Access role: public.
/// - a law to assign a delegate role to a nominated account. Access role: delegate, using delegate election vote.
/// - a preset self destruct law to assign role to previous DAO. Access role = admin. 
/// 


