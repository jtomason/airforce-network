#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

jq --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "Please Install 'jq' https://stedolan.github.io/jq/ to execute this script"
	echo
	exit 1
fi

starttime=$(date +%s)

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  ./testAPIs.sh -l golang|node"
  echo "    -l <language> - chaincode language (defaults to \"golang\")"
}
# Language defaults to "golang"
LANGUAGE="golang"

# Parse commandline args
while getopts "h?l:" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    l)  LANGUAGE=$OPTARG
    ;;
  esac
done

##set chaincode path
function setChaincodePath(){
	LANGUAGE=`echo "$LANGUAGE" | tr '[:upper:]' '[:lower:]'`
	case "$LANGUAGE" in
		"golang")
		CC_SRC_PATH="github.com/example_cc/go"
		;;
		"node")
		CC_SRC_PATH="$PWD/artifacts/src/github.com/example_cc/node"
		;;
		*) printf "\n ------ Language $LANGUAGE is not supported yet ------\n"$
		exit 1
	esac
}

setChaincodePath

echo "==================================================="
echo "=================== Enrolling users ==============="
echo "==================================================="


echo "POST request Enroll on Org1  ..."
echo
ORG1_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Jim&orgName=Org1')
echo $ORG1_TOKEN
ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG1 token is $ORG1_TOKEN"
echo
echo "POST request Enroll on Org2 ..."
echo
ORG2_TOKEN=$(curl -s -X POST \
  http://localhost:4000/users \
  -H "content-type: application/x-www-form-urlencoded" \
  -d 'username=Barry&orgName=Org2')
echo $ORG2_TOKEN
ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")
echo
echo "ORG2 token is $ORG2_TOKEN"
echo

echo "==================================================="
echo "=================== Channel Setup ==============="
echo "==================================================="
echo
echo "POST request Create shared channel  ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"mychannel",
	"channelConfigPath":"../artifacts/channel/mychannel.tx"
}'
echo
echo
sleep 5



echo "POST request creating the airforce private channel ..."
echo
curl -s -X POST \
  http://localhost:4000/channels \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"channelName":"afchannel",
	"channelConfigPath":"../artifacts/channel/afchannel.tx"
}'
echo
echo
sleep 5


echo "POST request Join airforce channel on Org1"
echo
curl -s -X POST \
  http://localhost:4000/channels/afchannel/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer1.org1.example.com"]
}'
echo
echo


echo "POST Install airforce chaincode chaincode on Org1 peers"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\",\"peer1.org1.example.com\"],
	\"chaincodeName\":\"afcc\",
	\"chaincodePath\":\"github.com/afcc/go\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo

echo 
echo "POST instantiate airforce chaincode on Org1 (instantiating takes a bit longer)"
echo
curl -s -X POST \
  http://localhost:4000/channels/afchannel/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"afcc\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo


echo "POST request Join the shared channel on Org1 peers"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer1.org1.example.com"]
}'
echo
echo

echo "POST request Join shared channel on Org2 peers"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/peers \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org2.example.com","peer1.org2.example.com"]
}'
echo
echo

echo "POST Install chaincode on Org1 peers"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org1.example.com\",\"peer1.org1.example.com\"],
	\"chaincodeName\":\"mycc\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo


echo "POST Install chaincode on Org2"
echo
curl -s -X POST \
  http://localhost:4000/chaincodes \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"peers\": [\"peer0.org2.example.com\",\"peer1.org2.example.com\"],
	\"chaincodeName\":\"mycc\",
	\"chaincodePath\":\"$CC_SRC_PATH\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"chaincodeVersion\":\"v0\"
}"
echo
echo



echo "POST instantiate chaincode on Org1 - may take awhile"
echo "No need to instantiate on org2 - only needed to instantiate once on channel"
echo
curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d "{
	\"chaincodeName\":\"mycc\",
	\"chaincodeVersion\":\"v0\",
	\"chaincodeType\": \"$LANGUAGE\",
	\"args\":[\"a\",\"100\",\"b\",\"200\"]
}"
echo
echo

echo "==================================================="
echo "======= Testing Chaincode on Shared Channel ======="
echo "==================================================="


echo "POST intializing the ledger throught invoke chaincode on peers of Org1 and Org2"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer0.org2.example.com"],
	"fcn":"initLedger",
	"args":["a","b","10"]
}')
echo "Transaction ID is $TRX_ID"
echo
echo


echo "POST invoke create door chaincode on peers of Org1 and Org2"
echo 'The door as the following information with a key of DOOR50 and a value of :
    Door{Location: Building 123 Room 50, DateInstalled: 1542201127, DateExpires: 1541651127, Entering:555, Exiting: 666}'
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com","peer0.org2.example.com"],
	"fcn":"createDoor",
	"args":["DOOR50","Building 123 Room 50","1542201127","1541651127","555","666"]
}')
echo "Transaction ID is $TRX_ID"
echo
echo

echo "POST query by key chaincode on peers of Org1 for the door just created"
echo
QR=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"queryByKey",
	"args":["DOOR50"]
}')
echo "Query response is $QR"
echo
echo

echo "POST query by date expires chaincode on peers of Org1 (a lower timestampe, so the door should not be included)"
echo
QR=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"queryByDateExpires",
	"args":["1542201120"]
}')
echo "Query response is $QR"
echo
echo

echo "POST query by date expires chaincode on peers of Org1 (a higher timestampe, so the door should be included)"
echo
QR=$(curl -s -X POST \
  http://localhost:4000/channels/mychannel/chaincodes/mycc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"queryByDateExpires",
	"args":["1542201130"]
}')
echo "Query response is $QR"
echo
echo




echo "==================================================="
echo "====== Testing Chaincode on Private Channel ======="
echo "==================================================="



echo "POST invoke create member on private chaincode on peers of Org1"
echo "Key is MEM10 and name is Bobby"
echo
TRX_ID=$(curl -s -X POST \
  http://localhost:4000/channels/afchannel/chaincodes/afcc \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peers": ["peer0.org1.example.com"],
	"fcn":"putMember",
	"args":["MEM10","Bobby",""]
}')
echo "Transaction ID is $TRX_ID"
echo
echo

echo "POST query by key chaincode on peers of Org1 for member just created"
echo
QR=$(curl -s -X POST \
  http://localhost:4000/channels/afchannel/chaincodes/afcc/query \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"queryByKey",
	"args":["MEM10"]
}')
echo "Query response is $QR"
echo
echo

echo "POST query by key chaincode on Org2 (which should not have access)"
echo
QR=$(curl -s -X POST \
  http://localhost:4000/channels/afchannel/chaincodes/afcc/query \
  -H "authorization: Bearer $ORG2_TOKEN" \
  -H "content-type: application/json" \
  -d '{
	"peer": "peer0.org1.example.com",
	"fcn":"queryByKey",
	"args":["MEM10"]
}')
echo "Query response is $QR"
echo
echo

echo 
echo "==================================================="
echo "====== Checking out the genesis blocks ======="
echo "==================================================="

echo "GET query genesis block on mychannel"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/blocks/0?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  > mychannelGenesisBlock.txt
echo
echo
echo "============================================"
echo
echo "GET query genesis block on afchannel"
echo
curl -s -X GET \
  "http://localhost:4000/channels/afchannel/blocks/0?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json" \
  > afchannelGenesisBlock.txt
echo
echo

echo "Saving tokens to tokens.txt"
echo "$ORG1_TOKEN" > tokens.txt
echo "$ORG2_TOKEN" >> tokens.txt

exit

#Below are some more scripts that was in balance transfer

echo "GET query chaincode on peer1 of Org1"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes/mycc?peer=peer0.org1.example.com&fcn=query&args=%5B%22a%22%5D" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Block by blockNumber"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/blocks/1?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Transaction by TransactionID"
echo
curl -s -X GET http://localhost:4000/channels/mychannel/transactions/$TRX_ID?peer=peer0.org1.example.com \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

############################################################################
### TODO: What to pass to fetch the Block information
############################################################################
#echo "GET query Block by Hash"
#echo
#hash=????
#curl -s -X GET \
#  "http://localhost:4000/channels/mychannel/blocks?hash=$hash&peer=peer1" \
#  -H "authorization: Bearer $ORG1_TOKEN" \
#  -H "cache-control: no-cache" \
#  -H "content-type: application/json" \
#  -H "x-access-token: $ORG1_TOKEN"
#echo
#echo

echo "GET query ChainInfo"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Installed chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/chaincodes?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Instantiated chaincodes"
echo
curl -s -X GET \
  "http://localhost:4000/channels/mychannel/chaincodes?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo

echo "GET query Channels"
echo
curl -s -X GET \
  "http://localhost:4000/channels?peer=peer0.org1.example.com" \
  -H "authorization: Bearer $ORG1_TOKEN" \
  -H "content-type: application/json"
echo
echo


echo "Total execution time : $(($(date +%s)-starttime)) secs ..."