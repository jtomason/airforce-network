Airforce Network 
    An example of how blockchain can be used for maintenance on equipment for the Airforce.
Problem Statement
    1) The Airforce wants to implement a blockchain to help keep track of maintenance on equipment throughout its infrastructure.
    2) All information stored must be secured and private with appropriate authentication.
    3) The Airforce wants to be able to have actionable insights into potential maintenance problems.
    4) There should be the potential to expand the network, perhaps by bringing its supply chain for maintenance into the network.
    5) Potentially create an Angular (or frontend) App for end users to access the network.
Solution Design
    The "balance-transfer" app from the "fabric-samples" was used as a base create the network.
    To keep the structure simple, the network will have two organizations. Org1 will be representative of the Airforce. Org2 will be representative of a maintenance contractor, in this case, maintenance for doors.
    1) Hyperledger Fabric was chosen to implement the blockchain. It is a flexible and comprehensive blockchain with all components to implement all the needs requested by the Airforce.
    2) Hyperledger Fabric has many methods to keep information secure - channels, private data, and storage capable of holding encrypted data.
        The method chosen to keep certain data private was separate channels. This network has two channels:
            The Shared Channel (aka channel 1 or mychannel) is accessed by both organizations and is were maintenance information about the doors is stored.
                The ledger for this channel will hold a single list of doors. 
                    A door has a key of its unique id and value of date installed, date expires (ie, when it must be replaced), number of people entering and number of people exiting.
            The Private Channel (aka channel 2 or afchannel) is accessed only by the Airforce. 
                This ledger will only hold a very simple data structure, Member. A member has a key of their unique id and a value of a name. 
            Both channels use JSON to store the information.
    3) To provide actionable insights, a query by data expires was implemented. 
        This allows the client to search for doors that must be replaced at a given date.
        For Hyperledger Fabric to perform this complex query, couchdb must be used. 
            Only peer1.org1 has couchdb installed (faster development time) so any time you wish to query by this, that peer must be used in the invocation.
    4) To create channels, join channels, install chaincode and invoke chaincode, a restful nodejs app was used (repurposed from the balance transfer example).
        This holds reusable endpoints/code to expand the network.
        Additionally, the design allows for Org2 to be used as the organization for ALL contractors. 
            However, this takes away participation power from members of org2 as the network would not be utilizing the power of Fabric's organization and MSP systems. 
    5) This is not yet implemented.

Usage
    Prereqs - same prereqs as the hyperledger fabric documentation for "Getting Started" section Building your first network.
    To tear down an old network, start the new network and start a client nodejs app, use "runApp.sh" script
    To create channels, join channels, install chaincode and run tests on the network, use "testAPIs.sh" script
    To cleanup the docker containers, run the "cleanup.sh" script.

    The runApp.sh scripts starts several docker containers to host certificate authorities, orderers and peers.
    It additionally starts a restful nodejs app with several endpoints to create channels, join peers to channels,
        install chaincode, instantiate chaincode, invoke chaincode and query the ledger.

    The testAPI.sh script is mostly just calling endpoints, so this could be done with any service that can make post requests.
        Postman was another useful tool in testing the endpoints.

TODO:
    Figure out how the genesis block in the second channel is being created. 
        I did not create one using the configtxgen, so I would like to know the source of the first block.
        This could also lead to policy/endorsing issues.
    Create a new organization on a running network and add it to a channel
        Only have found how to do this with the CLI, nothing so far with node sdk 
        Not sure if this can even be done. If it can't, how is this done on production systems?
            Isn't CLI designed for development and not production?
    Test various types of users (not just admins) and their abilities.
    Try to deploy a network for closer to production.
        Use multple orderers and deploy docker containers to different hosts