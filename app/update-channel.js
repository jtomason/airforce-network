/**
 *
 * SPDX-License-Identifier: Apache-2.0
 */

const utils = require('fabric-client/lib/utils.js');
const logger = utils.getLogger('E2E setAnchorPeers');


const Client = require('fabric-client');
const fs = require('fs');
const path = require('path');

var helper = require('./helper.js');

var updateChannel = async (org_name, channelName, anchorPeerTxFile, username) => {
    var client = await helper.getClientForOrg(org_name, username);
    

	const channelConfig_envelop = fs.readFileSync(anchorPeerTxFile);
	const channelConfig = client.extractChannelConfig(channelConfig_envelop);
    let signature = client.signChannelConfig(channelConfig);
	const request = {
		config: channelConfig,
		signatures: [signature],
		name: channelName,
		orderer:client.getOrderer("orderer.example.com"),
		txId: client.newTransactionID()
	};

	const result = await client.updateChannel(request);

	logger.info(`set AnchorPeers on channel ${channelName}`, result);
	return result;
};
exports.updateChannel = updateChannel;