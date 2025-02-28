import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test task creation and retrieval",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const futureTime = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
    
    let block = chain.mineBlock([
      Tx.contractCall('pulse-beam', 'create-task',
        [types.ascii("Test task"), types.uint(futureTime), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    const response = chain.callReadOnlyFn(
      'pulse-beam',
      'get-task',
      [types.uint(1)],
      deployer.address
    );
    
    const task = response.result.expectSome().expectTuple();
    assertEquals(task.description, "Test task");
    assertEquals(task.completed, false);
  }
});

Clarinet.test({
  name: "Test task completion",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const futureTime = Math.floor(Date.now() / 1000) + 86400;
    
    // Create task
    let block = chain.mineBlock([
      Tx.contractCall('pulse-beam', 'create-task',
        [types.ascii("Test task"), types.uint(futureTime), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    
    // Complete task as owner
    block = chain.mineBlock([
      Tx.contractCall('pulse-beam', 'complete-task',
        [types.uint(1), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try complete task as non-owner
    block = chain.mineBlock([
      Tx.contractCall('pulse-beam', 'complete-task',
        [types.uint(1), types.principal(wallet1.address)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(101); // ERR-UNAUTHORIZED
  }
});

Clarinet.test({
  name: "Test notification preferences",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Set notification preferences
    let block = chain.mineBlock([
      Tx.contractCall('pulse-beam', 'set-notifications',
        [types.bool(true), types.bool(false), types.principal(deployer.address)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Get notification preferences
    const response = chain.callReadOnlyFn(
      'pulse-beam',
      'get-notifications',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    const prefs = response.result.expectTuple();
    assertEquals(prefs['light-enabled'], true);
    assertEquals(prefs['sound-enabled'], false);
  }
});
