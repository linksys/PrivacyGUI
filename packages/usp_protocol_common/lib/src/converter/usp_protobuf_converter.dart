import 'package:collection/collection.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import '../generated/usp_msg.pb.dart' as pb;

/// A utility class for converting between USP DTOs and Protobuf messages.
class UspProtobufConverter {
  /// Converts a [UspMessage] DTO to a Protobuf [pb.Msg].
  pb.Msg toProto(UspMessage dto, {required String msgId}) {
    final header = pb.Header()
      ..msgId = msgId
      ..msgType = _getMsgType(dto);

    final body = pb.Body();

    // --- Requests (Including Notify) ---
    if (dto is UspRequest) {
      switch (dto) {
        // CRUD
        case UspGetRequest():
          final getMsg = pb.Get()
            ..paramPaths.addAll(dto.paths.map((p) => p.fullPath));
          body.request = pb.Request()..get = getMsg;

        case UspSetRequest():
          body.request = pb.Request()..set = _buildSetMsg(dto);

        case UspAddRequest():
          body.request = pb.Request()..add = _buildAddMsg(dto);

        case UspDeleteRequest():
          final delMsg = pb.Delete()
            ..objPaths.addAll(dto.objPaths.map((p) => p.fullPath))
            ..allowPartial = dto.allowPartial;
          body.request = pb.Request()..delete = delMsg;

        case UspOperateRequest():
          body.request = pb.Request()..operate = _buildOperateMsg(dto);

        case UspGetSupportedDMRequest():
          body.request = pb.Request()
            ..getSupportedDm = _buildGetSupportedDMMsg(dto);

        case UspGetInstancesRequest():
          body.request = pb.Request()
            ..getInstances = _buildGetInstancesMsg(dto);

        // Notifications (Special Request)
        case UspNotify():
          body.request = pb.Request()..notify = _buildNotifyMsg(dto);
      }
    }
    // --- Responses ---
    else if (dto is UspResponse) {
      switch (dto) {
        case UspGetResponse():
          body.response = pb.Response()..getResp = _buildGetResp(dto);

        case UspSetResponse():
          body.response = pb.Response()..setResp = _buildSetResp(dto);

        case UspAddResponse():
          body.response = pb.Response()..addResp = _buildAddResp(dto);

        case UspDeleteResponse():
          body.response = pb.Response()..deleteResp = _buildDeleteResp(dto);

        case UspOperateResponse():
          body.response = pb.Response()..operateResp = _buildOperateResp(dto);

        case UspGetSupportedDMResponse():
          body.response = pb.Response()
            ..getSupportedDmResp = _buildGetSupportedDMResp(dto);

        case UspGetInstancesResponse():
          body.response = pb.Response()
            ..getInstancesResp = _buildGetInstancesResp(dto);

        case UspNotifyResponse():
          body.response = pb.Response()
            ..notifyResp = (pb.NotifyResp()
              ..subscriptionId = dto.subscriptionId);

        case UspErrorResponse():
          final err = pb.Error()
            ..errCode = dto.exception.errorCode
            ..errMsg = dto.exception.message; // 假設你的 exception 有 message 欄位
          body.error = err;
      }
    } else {
      throw UspException(7004, "Unsupported DTO type: ${dto.runtimeType}");
    }

    return pb.Msg()
      ..header = header
      ..body = body;
  }

  /// Converts a Protobuf [pb.Msg] to a [UspMessage] DTO.
  UspMessage fromProto(pb.Msg protoMsg) {
    final body = protoMsg.body;

    switch (body.whichMsgBody()) {
      case pb.Body_MsgBody.request:
        return _parseRequest(body.request);
      case pb.Body_MsgBody.response:
        return _parseResponse(body.response);
      case pb.Body_MsgBody.error:
        return UspErrorResponse(
          UspException(body.error.errCode, body.error.errMsg),
        );
      case pb.Body_MsgBody.notSet:
        throw UspException(7004, "Empty or unknown Message Body");
    }
  }

  UspRequest _parseRequest(pb.Request req) {
    switch (req.whichReqType()) {
      case pb.Request_ReqType.get:
        return UspGetRequest(
          req.get.paramPaths.map((s) => UspPath.parse(s)).toList(),
        );
      case pb.Request_ReqType.set:
        return _parseSetMsg(req.set);
      case pb.Request_ReqType.add:
        return _parseAddMsg(req.add);
      case pb.Request_ReqType.delete:
        return UspDeleteRequest(
          req.delete.objPaths.map((s) => UspPath.parse(s)).toList(),
          allowPartial: req.delete.allowPartial,
        );
      case pb.Request_ReqType.operate:
        return _parseOperateMsg(req.operate);
      case pb.Request_ReqType.notify:
        return _parseNotifyMsg(req.notify);
      case pb.Request_ReqType.getSupportedDm:
        return _parseGetSupportedDMRequest(req.getSupportedDm);
      case pb.Request_ReqType.getInstances:
        return _parseGetInstancesMsg(req.getInstances);
      default:
        throw UspException(
          7004,
          "Unsupported Request Type: ${req.whichReqType()}",
        );
    }
  }

  UspResponse _parseResponse(pb.Response resp) {
    switch (resp.whichRespType()) {
      case pb.Response_RespType.getResp:
        return _parseGetResp(resp.getResp);
      case pb.Response_RespType.setResp:
        return _parseSetResp(resp.setResp);
      case pb.Response_RespType.addResp:
        return _parseAddResp(resp.addResp);
      case pb.Response_RespType.deleteResp:
        return _parseDeleteResp(resp.deleteResp);
      case pb.Response_RespType.operateResp:
        return _parseOperateResponse(resp.operateResp);
      case pb.Response_RespType.notifyResp:
        return UspNotifyResponse(
          subscriptionId: resp.notifyResp.subscriptionId,
        );
      case pb.Response_RespType.getSupportedDmResp:
        return _parseGetSupportedDMResp(resp.getSupportedDmResp);
      case pb.Response_RespType.getInstancesResp:
        return _parseGetInstancesResp(resp.getInstancesResp);
      default:
        throw UspException(
          7004,
          "Unsupported Response Type: ${resp.whichRespType()}",
        );
    }
  }

  // ========================================================================
  // Helpers: Logic & Mapping
  // ========================================================================

  pb.Header_MsgType _getMsgType(UspMessage dto) {
    return switch (dto) {
      UspGetRequest() => pb.Header_MsgType.GET,
      UspSetRequest() => pb.Header_MsgType.SET,
      UspAddRequest() => pb.Header_MsgType.ADD,
      UspDeleteRequest() => pb.Header_MsgType.DELETE,
      UspOperateRequest() => pb.Header_MsgType.OPERATE,
      UspGetSupportedDMRequest() => pb.Header_MsgType.GET_SUPPORTED_DM,
      UspGetInstancesRequest() => pb.Header_MsgType.GET_INSTANCES,
      UspNotify() => pb.Header_MsgType.NOTIFY,

      UspGetResponse() => pb.Header_MsgType.GET_RESP,
      UspSetResponse() => pb.Header_MsgType.SET_RESP,
      UspAddResponse() => pb.Header_MsgType.ADD_RESP,
      UspDeleteResponse() => pb.Header_MsgType.DELETE_RESP,
      UspOperateResponse() => pb.Header_MsgType.OPERATE_RESP,
      UspNotifyResponse() => pb.Header_MsgType.NOTIFY_RESP,
      UspGetSupportedDMResponse() => pb.Header_MsgType.GET_SUPPORTED_DM_RESP,
      UspGetInstancesResponse() => pb.Header_MsgType.GET_INSTANCES_RESP,
      UspErrorResponse() => pb.Header_MsgType.ERROR,
      _ => pb.Header_MsgType.ERROR,
    };
  }

  // ------------------------------------------------------------------------
  // Build Helpers (DTO -> Proto)
  // ------------------------------------------------------------------------

  pb.Set _buildSetMsg(UspSetRequest dto) {
    final setMsg = pb.Set()..allowPartial = dto.allowPartial;

    final groupedUpdates = dto.updates.entries.groupListsBy(
      (entry) => entry.key.parent?.fullPath ?? "",
    );

    groupedUpdates.forEach((objPath, entries) {
      if (objPath.isEmpty) return;

      final updateObj = pb.Set_UpdateObject()..objPath = objPath;
      for (final entry in entries) {
        updateObj.paramSettings.add(
          pb.Set_UpdateParamSetting()
            ..param = entry.key.name
            ..value = entry.value.value.toString()
            ..required = true,
        );
      }
      setMsg.updateObjs.add(updateObj);
    });

    return setMsg;
  }

  pb.Add _buildAddMsg(UspAddRequest dto) {
    final addMsg = pb.Add()..allowPartial = dto.allowPartial;

    for (final objCreation in dto.objects) {
      final createObj = pb.Add_CreateObject()
        ..objPath = objCreation.parentPath.fullPath;

      objCreation.parameters.forEach((key, val) {
        createObj.paramSettings.add(
          pb.Add_CreateParamSetting()
            ..param = key
            ..value = val.value.toString()
            ..required = true,
        );
      });
      addMsg.createObjs.add(createObj);
    }
    return addMsg;
  }

  /// [Lossy Conversion] Note: According to the TR-369 (USP) specification, all
  /// input/output arguments for an Operate message MUST be strings at the
  /// Protobuf layer.
  ///
  /// This means that during the `toProto` process, the `value.toString()`
  /// representation will be used, even if the original `UspValue` held an
  /// integer or boolean.
  ///
  /// Consequently, during the `fromProto` process, all arguments are parsed back
  /// as a `UspValue` with a `String` type, as the original type information is
  /// lost at the protocol level.
  ///
  /// Round-trip tests for Operate-related DTOs should therefore account for
  /// this lossy conversion and expect non-string types to become strings.
  pb.Operate _buildOperateMsg(UspOperateRequest dto) {
    final operateMsg = pb.Operate()..command = dto.command.fullPath;
    dto.inputArgs.forEach((key, value) {
      operateMsg.inputArgs[key] = value.value
          .toString(); // Assuming all inputArgs are string for now
    });
    return operateMsg;
  }

  pb.Notify_OperationComplete _buildOperationCompleteNotifyMsg(
    UspOperationCompleteNotify n,
  ) {
    final operComplete = pb.Notify_OperationComplete()
      ..objPath = n.objPath.fullPath
      ..commandName = n.commandName
      ..commandKey = n.commandKey;

    if (n.commandFailure == null) {
      operComplete.reqOutputArgs = pb.Notify_OperationComplete_OutputArgs()
        ..outputArgs.addAll(n.outputArgs);
    } else {
      operComplete.cmdFailure = pb.Notify_OperationComplete_CommandFailure()
        ..errCode = n.commandFailure!.errorCode
        ..errMsg = n.commandFailure!.message;
    }
    return operComplete;
  }

  // --- GetSupportedDM Request ---

  pb.GetSupportedDM _buildGetSupportedDMMsg(UspGetSupportedDMRequest dto) {
    return pb.GetSupportedDM()
      ..objPaths.addAll(dto.objPaths.map((p) => p.fullPath))
      ..firstLevelOnly = dto.firstLevelOnly
      ..returnCommands = dto.returnCommands
      ..returnEvents = dto.returnEvents
      ..returnParams = dto.returnParams;
    // 如果 DTO 有 returnUniqueKeySets，也要加進來
    // ..returnUniqueKeySets = dto.returnUniqueKeySets;
  }

  // --- GetInstances Request ---

  pb.GetInstances _buildGetInstancesMsg(UspGetInstancesRequest dto) {
    return pb.GetInstances()
      ..objPaths.addAll(dto.objPaths.map((p) => p.fullPath))
      ..firstLevelOnly = dto.firstLevelOnly;
  }

  pb.Notify _buildNotifyMsg(UspNotify dto) {
    final notifyMsg = pb.Notify()
      ..subscriptionId = dto.subscriptionId
      ..sendResp = dto.sendResp;

    if (dto is UspValueChangeNotify) {
      notifyMsg.valueChange = (pb.Notify_ValueChange()
        ..paramPath = dto.paramPath.fullPath
        ..paramValue = dto.paramValue);
    } else if (dto is UspObjectCreationNotify) {
      notifyMsg.objCreation = (pb.Notify_ObjectCreation()
        ..objPath = dto.objPath.fullPath
        ..uniqueKeys.addAll(dto.uniqueKeys));
    } else if (dto is UspObjectDeletionNotify) {
      notifyMsg.objDeletion = (pb.Notify_ObjectDeletion()
        ..objPath = dto.objPath.fullPath);
    } else if (dto is UspOperationCompleteNotify) {
      notifyMsg.operComplete = _buildOperationCompleteNotifyMsg(dto);
    } else if (dto is UspOnBoardRequestNotify) {
      notifyMsg.onBoardReq = (pb.Notify_OnBoardRequest()
        ..oui = dto.oui
        ..productClass = dto.productClass
        ..serialNumber = dto.serialNumber
        ..agentSupportedProtocolVersions = dto.agentProtocolVersions);
    } else {
      throw UspException(7004, "Unsupported Notify type: ${dto.runtimeType}");
    }
    return notifyMsg;
  }

  pb.OperateResp _buildOperateResp(UspOperateResponse dto) {
    final operateResp = pb.OperateResp();

    final operationResult = pb.OperateResp_OperationResult()
      ..executedCommand =
          "placeholder.command()"; // Using the name we corrected in the last round

    // --- Start of fix ---

    // 1. Explicitly create a new OutputArgs wrapper object
    final outputArgsWrapper = pb.OperateResp_OperationResult_OutputArgs();

    // 2. Fill the new object's map with data
    dto.outputArgs.forEach((key, value) {
      // Also solving problem 2 here (convert to string)
      outputArgsWrapper.outputArgs[key] = value.value.toString();
    });

    // 3. Assign the populated object to the parent
    // This will overwrite the original read-only default instance
    operationResult.reqOutputArgs = outputArgsWrapper;

    // --- End of fix ---

    operateResp.operationResults.add(operationResult);
    return operateResp;
  }

  pb.GetResp _buildGetResp(UspGetResponse dto) {
    final getResp = pb.GetResp();

    final groupedResults =
        <
          String,
          Map<String, UspValue>
        >{}; // <object_path, <param_name, UspValue>>

    dto.results.forEach((path, value) {
      final parentPath = path.parent?.fullPath ?? "";
      final paramName = path.name;

      if (!groupedResults.containsKey(parentPath)) {
        groupedResults[parentPath] = {};
      }
      groupedResults[parentPath]![paramName] = value;
    });

    // Create one RequestedPathResult for simplification, or one per actual request path in the future
    // Assuming requestedPath is empty or a generic one for simplicity as it's not in UspGetResponse DTO
    final reqPathRes = pb.GetResp_RequestedPathResult()
      ..errCode = 0; // Simplified

    groupedResults.forEach((objPath, params) {
      final resolved = pb.GetResp_ResolvedPathResult()
        ..resolvedPath = objPath; // This is the object path
      params.forEach((paramName, uspValue) {
        resolved.resultParams[paramName] = uspValue.value
            .toString(); // Param name -> value
      });
      reqPathRes.resolvedPathResults.add(resolved);
    });

    getResp.reqPathResults.add(reqPathRes);
    return getResp;
  }

  pb.SetResp _buildSetResp(UspSetResponse dto) {
    final setResp = pb.SetResp();

    // Success
    for (final path in dto.successPaths) {
      final successResult = pb.SetResp_UpdatedObjectResult()
        ..requestedPath = path
            .fullPath // Simplify: assuming object path
        ..operStatus = (pb.SetResp_UpdatedObjectResult_OperationStatus()
          ..operSuccess =
              pb.SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess());
      setResp.updatedObjResults.add(successResult);
    }

    // Failure
    dto.failurePaths.forEach((path, error) {
      final failureResult = pb.SetResp_UpdatedObjectResult()
        ..requestedPath = path.fullPath
        ..operStatus = (pb.SetResp_UpdatedObjectResult_OperationStatus()
          ..operFailure =
              (pb.SetResp_UpdatedObjectResult_OperationStatus_OperationFailure()
                ..errCode = error.errorCode
                ..errMsg = error.message));
      setResp.updatedObjResults.add(failureResult);
    });

    return setResp;
  }

  pb.AddResp _buildAddResp(UspAddResponse dto) {
    final addResp = pb.AddResp();

    for (final created in dto.createdObjects) {
      final result = pb.AddResp_CreatedObjectResult()
        ..requestedPath =
            created.instantiatedPath.parent?.fullPath ??
            "" // Or the requested path if available
        ..operStatus = (pb.AddResp_CreatedObjectResult_OperationStatus()
          ..operSuccess =
              (pb.AddResp_CreatedObjectResult_OperationStatus_OperationSuccess()
                ..instantiatedPath = created.instantiatedPath.fullPath));
      addResp.createdObjResults.add(result);
    }

    // Handle errors from the DTO
    for (final error in dto.errors) {
      final errorResult = pb.AddResp_CreatedObjectResult()
        ..requestedPath =
            "error.path" // Placeholder: DTO UspException doesn't carry path
        ..operStatus = (pb.AddResp_CreatedObjectResult_OperationStatus()
          ..operFailure =
              (pb.AddResp_CreatedObjectResult_OperationStatus_OperationFailure()
                ..errCode = error.errorCode
                ..errMsg = error.message));
      addResp.createdObjResults.add(errorResult);
    }

    return addResp;
  }

  pb.DeleteResp _buildDeleteResp(UspDeleteResponse dto) {
    final delResp = pb.DeleteResp();

    for (final path in dto.deletedPaths) {
      final result = pb.DeleteResp_DeletedObjectResult()
        ..requestedPath = path.fullPath
        ..operStatus = (pb.DeleteResp_DeletedObjectResult_OperationStatus()
          ..operSuccess =
              pb.DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess());
      delResp.deletedObjResults.add(result);
    }

    // Handle errors from the DTO
    for (final error in dto.errors) {
      final errorResult = pb.DeleteResp_DeletedObjectResult()
        ..requestedPath =
            "error.path" // Placeholder: DTO UspException doesn't carry path
        ..operStatus = (pb.DeleteResp_DeletedObjectResult_OperationStatus()
          ..operFailure =
              (pb.DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure()
                ..errCode = error.errorCode
                ..errMsg = error.message));
      delResp.deletedObjResults.add(errorResult);
    }

    return delResp;
  }

  // --- GetSupportedDM Response ---

  pb.GetSupportedDMResp _buildGetSupportedDMResp(
    UspGetSupportedDMResponse dto,
  ) {
    final resp = pb.GetSupportedDMResp();

    // USP allows multiple Request Path.
    // Our DTO is flat Map<String, Definition>.
    // Here we simplify the processing: pack all results in a "empty path" or "Device." RequestedObjectResult.

    final reqObjResult = pb.GetSupportedDMResp_RequestedObjectResult()
      ..reqObjPath =
          "" // or "Device." depends on the original request
      ..errCode = 0;

    dto.results.forEach((path, def) {
      final supportedObj = pb.GetSupportedDMResp_SupportedObjectResult()
        ..supportedObjPath = def.path
        ..isMultiInstance = def.isMultiInstance
        ..access = _mapObjAccessToProto(def.access);

      // 1. Convert Parameters
      if (def.supportedParams.isNotEmpty) {
        def.supportedParams.forEach((name, paramDef) {
          final supportedParam = pb.GetSupportedDMResp_SupportedParamResult()
            ..paramName = name
            ..access = paramDef.isWritable
                ? pb.GetSupportedDMResp_ParamAccessType.PARAM_READ_WRITE
                : pb.GetSupportedDMResp_ParamAccessType.PARAM_READ_ONLY
            ..valueType = _mapParamTypeToProto(paramDef.type);

          supportedObj.supportedParams.add(supportedParam);
        });
      }

      // 2. Convert Commands
      if (def.supportedCommands.isNotEmpty) {
        def.supportedCommands.forEach((name, cmdDef) {
          final supportedCmd = pb.GetSupportedDMResp_SupportedCommandResult()
            ..commandName = name
            ..commandType = cmdDef.isAsync
                ? pb.GetSupportedDMResp_CmdType.CMD_ASYNC
                : pb.GetSupportedDMResp_CmdType.CMD_SYNC;

          supportedCmd.inputArgNames.addAll(cmdDef.inputArgs.keys);
          supportedCmd.outputArgNames.addAll(cmdDef.outputArgs.keys);

          supportedObj.supportedCommands.add(supportedCmd);
        });
      }

      // 3. Convert Events (if defined)
      // if (def.supportedEvents.isNotEmpty) { ... }

      reqObjResult.supportedObjs.add(supportedObj);
    });

    resp.reqObjResults.add(reqObjResult);
    return resp;
  }

  // --- GetInstances Response ---
  pb.GetInstancesResp _buildGetInstancesResp(UspGetInstancesResponse dto) {
    final resp = pb.GetInstancesResp();

    dto.results.forEach((reqPath, instances) {
      final reqResult = pb.GetInstancesResp_RequestedPathResult()
        ..requestedPath = reqPath
        ..errCode = 0;

      for (final inst in instances) {
        final currInst = pb.GetInstancesResp_CurrInstance()
          ..instantiatedObjPath = inst.instantiatedPath;

        if (inst.uniqueKeys.isNotEmpty) {
          currInst.uniqueKeys.addAll(inst.uniqueKeys);
        }

        reqResult.currInsts.add(currInst);
      }
      resp.reqPathResults.add(reqResult);
    });

    return resp;
  }

  // --- Enum Mapping Helpers ---

  pb.GetSupportedDMResp_ObjAccessType _mapObjAccessToProto(String access) {
    switch (access) {
      case 'ReadWrite':
      case 'readWrite':
        return pb.GetSupportedDMResp_ObjAccessType.OBJ_ADD_DELETE;

      case 'AddOnly':
      case 'addOnly':
        return pb.GetSupportedDMResp_ObjAccessType.OBJ_ADD_ONLY;

      case 'DeleteOnly':
      case 'deleteOnly':
        return pb.GetSupportedDMResp_ObjAccessType.OBJ_DELETE_ONLY;

      case 'ReadOnly':
      case 'readOnly':
      default:
        // 預設為最安全的唯讀
        return pb.GetSupportedDMResp_ObjAccessType.OBJ_READ_ONLY;
    }
  }

  pb.GetSupportedDMResp_ParamValueType _mapParamTypeToProto(UspValueType type) {
    switch (type) {
      case UspValueType.string:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_STRING;
      case UspValueType.int:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_INT;
      case UspValueType.unsignedInt:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_UNSIGNED_INT;
      case UspValueType.long:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_LONG;
      case UspValueType.unsignedLong:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_UNSIGNED_LONG;
      case UspValueType.boolean:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_BOOLEAN;
      case UspValueType.dateTime:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_DATE_TIME;
      case UspValueType.base64:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_BASE_64;
      case UspValueType.hexBinary:
        return pb.GetSupportedDMResp_ParamValueType.PARAM_HEX_BINARY;
    }
  }

  // ------------------------------------------------------------------------
  // Parse Helpers (Proto -> DTO)
  // ------------------------------------------------------------------------

  UspSetRequest _parseSetMsg(pb.Set setMsg) {
    final updates = <UspPath, UspValue>{};

    for (final obj in setMsg.updateObjs) {
      for (final param in obj.paramSettings) {
        final fullPath = "${obj.objPath}.${param.param}";
        updates[UspPath.parse(fullPath)] = UspValue(
          param.value,
          UspValueType.string,
        );
      }
    }
    return UspSetRequest(updates, allowPartial: setMsg.allowPartial);
  }

  UspAddRequest _parseAddMsg(pb.Add addMsg) {
    final objects = <UspObjectCreation>[];

    for (final obj in addMsg.createObjs) {
      final params = <String, UspValue>{};
      for (final p in obj.paramSettings) {
        params[p.param] = UspValue(p.value, UspValueType.string);
      }
      objects.add(
        UspObjectCreation(UspPath.parse(obj.objPath), parameters: params),
      );
    }
    return UspAddRequest(objects, allowPartial: addMsg.allowPartial);
  }

  UspOperateRequest _parseOperateMsg(pb.Operate operateMsg) {
    final inputArgs = <String, UspValue>{};
    operateMsg.inputArgs.forEach((key, value) {
      inputArgs[key] = UspValue(
        value,
        UspValueType.string,
      ); // Assuming string for simplicity
    });
    return UspOperateRequest(
      command: UspPath.parse(operateMsg.command),
      inputArgs: inputArgs,
    );
  }

  UspGetResponse _parseGetResp(pb.GetResp getResp) {
    final results = <UspPath, UspValue>{};

    for (final reqRes in getResp.reqPathResults) {
      for (final resolved in reqRes.resolvedPathResults) {
        final objPath = resolved.resolvedPath; // This is the object path
        resolved.resultParams.forEach((paramName, val) {
          final fullParamPath = UspPath.parse(
            "$objPath.$paramName",
          ); // Reconstruct full parameter path
          results[fullParamPath] = UspValue(
            val,
            UspValueType.string,
          ); // Assuming string for simplicity
        });
      }
    }
    return UspGetResponse(results);
  }

  UspNotify _parseNotifyMsg(pb.Notify notifyMsg) {
    return switch (notifyMsg.whichNotification()) {
      pb.Notify_Notification.valueChange => UspValueChangeNotify(
        paramPath: UspPath.parse(notifyMsg.valueChange.paramPath),
        paramValue: notifyMsg.valueChange.paramValue,
        subscriptionId: notifyMsg.subscriptionId,
        sendResp: notifyMsg.sendResp,
      ),
      pb.Notify_Notification.objCreation => UspObjectCreationNotify(
        objPath: UspPath.parse(notifyMsg.objCreation.objPath),
        uniqueKeys: notifyMsg.objCreation.uniqueKeys,
        subscriptionId: notifyMsg.subscriptionId,
        sendResp: notifyMsg.sendResp,
      ),
      pb.Notify_Notification.objDeletion => UspObjectDeletionNotify(
        objPath: UspPath.parse(notifyMsg.objDeletion.objPath),
        subscriptionId: notifyMsg.subscriptionId,
        sendResp: notifyMsg.sendResp,
      ),
      pb.Notify_Notification.operComplete => UspOperationCompleteNotify(
        objPath: UspPath.parse(notifyMsg.operComplete.objPath),
        commandName: notifyMsg.operComplete.commandName,
        commandKey: notifyMsg.operComplete.commandKey,
        outputArgs: notifyMsg.operComplete.hasReqOutputArgs()
            ? notifyMsg.operComplete.reqOutputArgs.outputArgs
            : {},
        commandFailure: notifyMsg.operComplete.hasCmdFailure()
            ? UspException(
                notifyMsg.operComplete.cmdFailure.errCode,
                notifyMsg.operComplete.cmdFailure.errMsg,
              )
            : null,
        subscriptionId: notifyMsg.subscriptionId,
        sendResp: notifyMsg.sendResp,
      ),
      pb.Notify_Notification.onBoardReq => UspOnBoardRequestNotify(
        oui: notifyMsg.onBoardReq.oui,
        productClass: notifyMsg.onBoardReq.productClass,
        serialNumber: notifyMsg.onBoardReq.serialNumber,
        agentProtocolVersions:
            notifyMsg.onBoardReq.agentSupportedProtocolVersions,
        sendResp: notifyMsg.sendResp,
      ),
      _ => throw UspException(
        7004,
        "Unsupported Notification Type: ${notifyMsg.whichNotification()}",
      ),
    };
  }

  UspSetResponse _parseSetResp(pb.SetResp setResp) {
    final success = <UspPath>[];
    final failures = <UspPath, UspException>{};

    for (final res in setResp.updatedObjResults) {
      final path = UspPath.parse(res.requestedPath);

      if (res.operStatus.hasOperSuccess()) {
        success.add(path);
      } else if (res.operStatus.hasOperFailure()) {
        final err = res.operStatus.operFailure;
        failures[path] = UspException(err.errCode, err.errMsg);
      }
    }
    return UspSetResponse(successPaths: success, failurePaths: failures);
  }

  UspAddResponse _parseAddResp(pb.AddResp addResp) {
    final created = <UspCreatedObject>[];
    final errors = <UspException>[];

    for (final res in addResp.createdObjResults) {
      if (res.operStatus.hasOperSuccess()) {
        final pathStr = res.operStatus.operSuccess.instantiatedPath;
        created.add(UspCreatedObject(UspPath.parse(pathStr)));
      } else if (res.operStatus.hasOperFailure()) {
        final err = res.operStatus.operFailure;
        errors.add(UspException(err.errCode, err.errMsg));
      }
    }
    return UspAddResponse(createdObjects: created, errors: errors);
  }

  UspDeleteResponse _parseDeleteResp(pb.DeleteResp delResp) {
    final deleted = <UspPath>[];
    final errors = <UspException>[];

    for (final res in delResp.deletedObjResults) {
      if (res.operStatus.hasOperSuccess()) {
        deleted.add(UspPath.parse(res.requestedPath));
      } else if (res.operStatus.hasOperFailure()) {
        final err = res.operStatus.operFailure;
        errors.add(UspException(err.errCode, err.errMsg));
      }
    }
    return UspDeleteResponse(deletedPaths: deleted, errors: errors);
  }

  UspOperateResponse _parseOperateResponse(pb.OperateResp operateResp) {
    // Renamed to avoid confusion
    final outputArgs = <String, UspValue>{};
    if (operateResp.operationResults.isNotEmpty) {
      // For simplicity, take the first operation result's reqOutputArgs
      operateResp.operationResults.first.reqOutputArgs.outputArgs.forEach((
        key,
        value,
      ) {
        // Changed to reqOutputArgs
        outputArgs[key] = UspValue(value, UspValueType.string);
      });
    }
    return UspOperateResponse(outputArgs: outputArgs);
  }

  // --- Parse GetSupportedDM Request ---
  UspGetSupportedDMRequest _parseGetSupportedDMRequest(pb.GetSupportedDM msg) {
    return UspGetSupportedDMRequest(
      msg.objPaths.map((s) => UspPath.parse(s)).toList(),
      firstLevelOnly: msg.firstLevelOnly,
      returnCommands: msg.returnCommands,
      returnEvents: msg.returnEvents,
      returnParams: msg.returnParams,
    );
  }

  // --- Parse GetSupportedDM Response ---
  UspGetSupportedDMResponse _parseGetSupportedDMResp(
    pb.GetSupportedDMResp resp,
  ) {
    final results = <String, UspObjectDefinition>{};

    for (final reqRes in resp.reqObjResults) {
      for (final supportedObj in reqRes.supportedObjs) {
        // 1. Parse Params
        final params = <String, UspParamDefinition>{};
        for (final p in supportedObj.supportedParams) {
          params[p.paramName] = UspParamDefinition(
            name: p.paramName,
            type: _mapProtoToParamType(p.valueType),
            isWritable:
                p.access ==
                pb.GetSupportedDMResp_ParamAccessType.PARAM_READ_WRITE,
            constraints: UspParamConstraints(),
          );
        }

        // 2. Parse Commands
        final commands = <String, UspCommandDefinition>{};
        for (final c in supportedObj.supportedCommands) {
          final inputMap = <String, UspArgumentDefinition>{};
          for (final argName in c.inputArgNames) {
            inputMap[argName] = UspArgumentDefinition(
              name: argName,
              type: UspValueType.string, // Default fallback
            );
          }

          final outputMap = <String, UspArgumentDefinition>{};
          for (final argName in c.outputArgNames) {
            outputMap[argName] = UspArgumentDefinition(
              name: argName,
              type: UspValueType.string, // Default fallback
            );
          }

          commands[c.commandName] = UspCommandDefinition(
            name: c.commandName, // 這裡修正建構子參數名稱
            inputArgs: inputMap,
            outputArgs: outputMap,
            isAsync: _isCommandAsync(c.commandType),
          );
        }

        // 3. Parse Object
        final def = UspObjectDefinition(
          path: supportedObj.supportedObjPath,
          isMultiInstance: supportedObj.isMultiInstance,
          access: _mapProtoToObjAccess(supportedObj.access),
          supportedParams: params,
          supportedCommands: commands,
        );

        results[supportedObj.supportedObjPath] = def;
      }
    }

    return UspGetSupportedDMResponse(results);
  }

  // --- Parse GetInstances Request ---
  UspGetInstancesRequest _parseGetInstancesMsg(pb.GetInstances msg) {
    return UspGetInstancesRequest(
      msg.objPaths.map((s) => UspPath.parse(s)).toList(),
      firstLevelOnly: msg.firstLevelOnly,
    );
  }

  // --- Parse GetInstances Response ---
  UspGetInstancesResponse _parseGetInstancesResp(pb.GetInstancesResp resp) {
    final results = <String, List<UspInstanceResult>>{};

    for (final reqRes in resp.reqPathResults) {
      final instances = <UspInstanceResult>[];

      for (final curr in reqRes.currInsts) {
        instances.add(
          UspInstanceResult(
            curr.instantiatedObjPath,
            uniqueKeys: curr.uniqueKeys, // Map<String, String>
          ),
        );
      }

      results[reqRes.requestedPath] = instances;
    }

    return UspGetInstancesResponse(results);
  }

  // --- Enum Mapping Helpers (Reverse) ---

  UspValueType _mapProtoToParamType(pb.GetSupportedDMResp_ParamValueType type) {
    switch (type) {
      case pb.GetSupportedDMResp_ParamValueType.PARAM_INT:
        return UspValueType.int;
      case pb.GetSupportedDMResp_ParamValueType.PARAM_UNSIGNED_INT:
        return UspValueType.unsignedInt;
      case pb.GetSupportedDMResp_ParamValueType.PARAM_BOOLEAN:
        return UspValueType.boolean;
      case pb.GetSupportedDMResp_ParamValueType.PARAM_DATE_TIME:
        return UspValueType.dateTime;
      // ... 其他對應 ...
      default:
        return UspValueType.string;
    }
  }

  String _mapProtoToObjAccess(pb.GetSupportedDMResp_ObjAccessType access) {
    switch (access) {
      case pb.GetSupportedDMResp_ObjAccessType.OBJ_ADD_DELETE:
        return "ReadWrite";
      case pb.GetSupportedDMResp_ObjAccessType.OBJ_READ_ONLY:
        return "ReadOnly";
      case pb.GetSupportedDMResp_ObjAccessType.OBJ_ADD_ONLY:
        return "AddOnly";
      case pb.GetSupportedDMResp_ObjAccessType.OBJ_DELETE_ONLY:
        return "DeleteOnly";
      default:
        return "ReadOnly";
    }
  }

  bool _isCommandAsync(pb.GetSupportedDMResp_CmdType type) {
    return type == pb.GetSupportedDMResp_CmdType.CMD_ASYNC;
  }
}
