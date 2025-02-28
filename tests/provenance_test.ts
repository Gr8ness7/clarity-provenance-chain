import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new product",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const product_id = "PROD001";
    const metadata = "Sample product metadata";
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "provenance",
        "register-product",
        [types.ascii(product_id), types.ascii(metadata)],
        deployer.address
      ),
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Ensure can't register with empty product ID",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const product_id = "";
    const metadata = "Sample product metadata";
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "provenance",
        "register-product",
        [types.ascii(product_id), types.ascii(metadata)],
        deployer.address
      ),
    ]);
    
    block.receipts[0].result.expectErr(types.uint(104));
  },
});

Clarinet.test({
  name: "Ensure can update product status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const product_id = "PROD001";
    const metadata = "Sample product metadata";
    const new_status = "active";
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "provenance",
        "register-product",
        [types.ascii(product_id), types.ascii(metadata)],
        deployer.address
      ),
      Tx.contractCall(
        "provenance",
        "update-status",
        [types.ascii(product_id), types.ascii(new_status)],
        deployer.address
      ),
    ]);
    
    block.receipts[1].result.expectOk();
  },
});
