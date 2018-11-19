#!/bin/bash

rm genesis.block
rm mychannel.tx

./configtxgen -profile TwoOrgsOrdererGenesis  -outputBlock ./genesis.block 

./configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./mychannel.tx -channelID mychannel