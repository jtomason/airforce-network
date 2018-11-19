#!/bin/bash

rm genesis.block
rm mychannel.tx

./configtxgen -profile TwoOrgsOrdererGenesis  -outputBlock ./genesis.block 

./configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./mychannel.tx -channelID mychannel

./configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP

./configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP

./configtxgen -profile OneOrgChannel -outputCreateChannelTx ./afchannel.tx -channelID afchannel
