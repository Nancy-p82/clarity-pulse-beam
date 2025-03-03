import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test enhanced task creation and retrieval",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const futureBlock = chain.blockHeight + 100;
    
    let block = chain.mineBlock([
      Tx.contractCall('pulse-beam', 'create-task',
        [
          types.ascii("Test task"),
          types.uint(futureBlock),
          types.principal(deployer.address),
          types.uint(1),
          types.some(types.ascii("work"))
        ],
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
    assertEquals(task.priority, 1);
    assertEquals(task.completed, false);
  }
});

// Additional tests...
