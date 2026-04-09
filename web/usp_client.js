/* @ts-self-types="./usp_client.d.ts" */

import * as wasm from "./usp_client_bg.wasm";
import { __wbg_set_wasm } from "./usp_client_bg.js";
__wbg_set_wasm(wasm);
wasm.__wbindgen_start();
export {
    UspClient, init
} from "./usp_client_bg.js";
