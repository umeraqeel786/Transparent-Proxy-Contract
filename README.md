# Upgradeable_Drone_Contract_Using_Transparent-Proxy_Pattern

**Note:** The instructions given below are for Ubuntu 20.04 LTS (users only).

## Steps to run the project

1. Clone the repository.
2. Install the dependencies using the following command: `npm i`.
3. Create a `.env` file in the project folder and add your `PRIVATEKEY`,`infuraID` **(RINKEBY_RPC_URL)** and `etherscan-API-key` in it in the following format:
   
  ``` 
  RINKEBY_RPC_URL='https://rinkeby.infura.io/v3/1d88d32449d64d7a94c6b55de216042e'
  PRIVATE_KEY=''
  ETHERSCAN_API_KEY= '8WKUUZ72WVPJ78UBI4TMHWT61UVA5FYI53'

   ```

4. Run the deployment script **deploy.js**  present in the scripts folder, using the following command:  
   `npx hardhat run --network rinkeby scripts/deploy.js` to deploy the **DroneContract**.
5. Now verify the deployed **DroneContract** on rinkeby testnet using the following command: 
   `npx hardhat verify --network rinkeby {implementation  contract-address of Drone_Contract}`
6. Once verified, your Etherscan transactions will look like this:
    ![Etherscan deployment](https://user-images.githubusercontent.com/52605353/174560518-1739fe01-5a13-48a6-a3f0-a17f0040ac59.png)
   
   In the proxy pattern, everything is stored and executed in the context of the proxy contract.So in-order to interact with the **DroneContract**,
   you should do it via the proxy contract. To do that, first we need to inform Etherscan that the deployed contract is actually a proxy.
   In the `Contract` tab of the proxy contract, there’ll be a small dropdown above the source code section (on the right side).
     
   ![Contract Tab](https://user-images.githubusercontent.com/52605353/174563888-1fef79b8-cefe-4f58-bde1-cc85ef9526e9.png)
  
   Choose **“Is this a proxy?”** option from the dropdown and then **Verify.**

   ![Is this a proxy?](https://user-images.githubusercontent.com/52605353/174564215-24b2abef-925c-42da-a0a8-bca0ae0dcb64.png)

    You can see **Read as Proxy** and **Write as Proxy** options in the `Contract` tab of the proxy contract.
    
   ![pic 4](https://user-images.githubusercontent.com/52605353/174565105-465a1bfa-905e-4b79-ad19-a24a624e40ae.png)

   Now you can interact with the **DroneContract** contract  using those options!   

7. We now change proxyAddress in **upgrade.js** with the new **DroneContractV2Proxy address** present in the code line `const proxyAddress =  '0x1397cbC428E0Bfc599eFB31640F909C12144CDB5';`
8. Once the **DroneContract** is deployed and verified on rinkeby testnet, we now need to deploy the upgraded implementation of Drone-Contract that
   is **DroneContractV2** by running the deployment script **upgrade.js** present in the scripts folder, using the following command:
   `npx hardhat run --network rinkeby scripts/upgrade.js` to deploy the **DroneContractV2**.
9. Now verify the deployed  **DroneContractV2** on rinkeby testnet using the following command:
   `npx hardhat verify --network rinkeby {implementation  contract-address of Drone_ContractV2}`
10. Once **DroneContractV2** verified on Etherscan, then perform the same procedure mentioned in the **step:6**.



   
