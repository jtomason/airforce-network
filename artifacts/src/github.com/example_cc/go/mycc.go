/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/*
 * The sample smart contract for documentation topic:
 * Writing Your First Blockchain Application
 */

 package main

 /* Imports
  * 4 utility libraries for formatting, handling bytes, reading and writing JSON, and string manipulation
  * 2 specific Hyperledger Fabric specific libraries for Smart Contracts
  */
 import (
	 "bytes"
	 "encoding/json"
	 "fmt"
	 "strconv"
 
	 "github.com/hyperledger/fabric/core/chaincode/shim"
	 sc "github.com/hyperledger/fabric/protos/peer"
 )
 
 // Define the Smart Contract structure
 type SmartContract struct {
 }
 
 type Door struct {
	 
	 Location  string `json:"location"`
	 DateInstalled  int `json:"dateinstalled"`
	 DateExpires int `json:"dateexpires"`
	 Entering  int `json:"entering"`
	 Exiting int `json:"exiting"`
 }

 type Member struct {
	 Name string `json:"name"`
 }

 
 func (s *SmartContract) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
	 return shim.Success(nil)
 }
 
 func (s *SmartContract) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {
 
	 // Retrieve the requested Smart Contract function and arguments
	 function, args := APIstub.GetFunctionAndParameters()
	 // Route to the appropriate handler function to interact with the ledger appropriately
	 if function == "queryByKey" {
		 return s.queryByKey(APIstub, args)
	 } else if function == "initLedger" {
		 return s.initLedger(APIstub)
	 } else if function == "createDoor" {
		 return s.createDoor(APIstub, args)
	 }  else if function == "queryByLocation" {
		return s.queryByLocation(APIstub, args)
	} else if function == "queryByDateExpires" {
		return s.queryByDateExpires(APIstub, args)
	} else if function == "putMember" {
		return s.putMember(APIstub, args)
	} else if function == "getMember" {
		return s.getMember(APIstub, args)
	}
 
	 return shim.Error("Invalid Smart Contract function name.")
 }
 
 func (s *SmartContract) queryByKey(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
 
	 if len(args) != 1 {
		 return shim.Error("Incorrect number of arguments. Expecting 1")
	 }
 
	 asBytes, _ := APIstub.GetState(args[0])
	 return shim.Success(asBytes)
 }

 func (s *SmartContract) putMember(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	// needs key id, member name, collection name
	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting 3")
	}

	var member = Member{Name: args[1]}
 
	 asBytes, _ := json.Marshal(member)
	APIstub.PutPrivateData(args[2], args[0], asBytes)
	 return shim.Success(nil)
}
func (s *SmartContract) getMember(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	//needs key id, collection name
	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}
	asBytes, _ := APIstub.GetPrivateData(args[1],args[0])
	return shim.Success(asBytes)
}


 
 func (s *SmartContract) initLedger(APIstub shim.ChaincodeStubInterface) sc.Response {
	 doors := []Door{


		 Door{Location: "Building 300 Room 217", DateInstalled: 1541599643, DateExpires: 1541651127, Entering: 55, Exiting: 66},
		 Door{Location: "Building 215 Room 117", DateInstalled: 1541599643, DateExpires: 1541651127, Entering: 5, Exiting: 6},
		 Door{Location: "Building 300 Room 222", DateInstalled: 1541599643, DateExpires: 1541651127, Entering: 100, Exiting: 122},
		 Door{Location: "Building 300 Room 111", DateInstalled: 1541599643, DateExpires: 1541651127, Entering: 1688, Exiting: 1577},
		 Door{Location: "Building 215 Room 500", DateInstalled: 1541599643, DateExpires: 1541651127, Entering: 33, Exiting: 34},
	 }
 
	 i := 0
	 for i < len(doors) {
		 fmt.Println("i is ", i)
		 asBytes, _ := json.Marshal(doors[i])
		 APIstub.PutState("DOOR"+strconv.Itoa(i), asBytes)
		 fmt.Println("Added", doors[i])
		 i = i + 1
	 }
 
	 return shim.Success(nil)
 }
 
 func (s *SmartContract) createDoor(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
	 if len(args) == 2{
		input := []byte(args[1])
	 
		mydoor := Door{} // Slice of Message instances
		json.Unmarshal(input, &mydoor)
		asBytes, _ := json.Marshal(mydoor)
		APIstub.PutState(args[0], asBytes)
	
		return shim.Success(nil)
	 }
 
	 if len(args) != 6 {
		 return shim.Error("Incorrect number of arguments. Expecting 5")
	 }



    /** converting the str1 variable into an int using Atoi method */
	de, _ := strconv.Atoi(args[2])
	di, _ := strconv.Atoi(args[3])
	entering, _ := strconv.Atoi(args[4])
	exiting, _ := strconv.Atoi(args[5])
    

	 var door = Door{Location: args[1], DateInstalled: di, DateExpires: de, Entering:entering, Exiting: exiting}
 
	 asBytes, _ := json.Marshal(door)
	 APIstub.PutState(args[0], asBytes)
 
	 return shim.Success(nil)
 }
 
 
 func (t *SmartContract) queryByDateExpires(stub shim.ChaincodeStubInterface, args []string) sc.Response {

	//   0
	// "bob"
	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	date, err := strconv.Atoi(args[0])
	if err != nil {
        // handle error
		return shim.Error(err.Error())
	
    }

	//queryString := fmt.Sprintf("{\"selector\":{\"dateexpires\": { \"$lt\": \"%s\"}}}", date)
	queryString := fmt.Sprintf("{\"selector\":{\"dateexpires\": { \"$lt\": %d}}}", date)

	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

 func (t *SmartContract) queryByLocation(stub shim.ChaincodeStubInterface, args []string) sc.Response {

	//   0
	// "bob"
	if len(args) < 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	location := args[0]

	queryString := fmt.Sprintf("{\"selector\":{\"location\":\"%s\"}}", location)

	queryResults, err := getQueryResultForQueryString(stub, queryString)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(queryResults)
}

func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {

	fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

	resultsIterator, err := stub.GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	buffer, err := constructQueryResponseFromIterator(resultsIterator)
	if err != nil {
		return nil, err
	}

	fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

	return buffer.Bytes(), nil
}

// ===========================================================================================
// constructQueryResponseFromIterator constructs a JSON array containing query results from
// a given result iterator
// ===========================================================================================
func constructQueryResponseFromIterator(resultsIterator shim.StateQueryIteratorInterface) (*bytes.Buffer, error) {
	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	return &buffer, nil
}

 
 // The main function is only relevant in unit test mode. Only included here for completeness.
 func main() {
 
	 // Create a new Smart Contract
	 err := shim.Start(new(SmartContract))
	 if err != nil {
		 fmt.Printf("Error creating new Smart Contract: %s", err)
	 }
 }
 