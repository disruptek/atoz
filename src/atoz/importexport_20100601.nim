
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Import/Export
## version: 2010-06-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Import/Export Service</fullname> AWS Import/Export accelerates transferring large amounts of data between the AWS cloud and portable storage devices that you mail to us. AWS Import/Export transfers data directly onto and off of your storage devices using Amazon's high-speed internal network and bypassing the Internet. For large data sets, AWS Import/Export is often faster than Internet transfer and more cost effective than upgrading your connectivity.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/importexport/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "importexport.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "importexport.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "importexport"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostCancelJob_21626018 = ref object of OpenApiRestCall_21625418
proc url_PostCancelJob_21626020(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCancelJob_21626019(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626021 = query.getOrDefault("SignatureMethod")
  valid_21626021 = validateParameter(valid_21626021, JString, required = true,
                                   default = nil)
  if valid_21626021 != nil:
    section.add "SignatureMethod", valid_21626021
  var valid_21626022 = query.getOrDefault("Signature")
  valid_21626022 = validateParameter(valid_21626022, JString, required = true,
                                   default = nil)
  if valid_21626022 != nil:
    section.add "Signature", valid_21626022
  var valid_21626023 = query.getOrDefault("Action")
  valid_21626023 = validateParameter(valid_21626023, JString, required = true,
                                   default = newJString("CancelJob"))
  if valid_21626023 != nil:
    section.add "Action", valid_21626023
  var valid_21626024 = query.getOrDefault("Timestamp")
  valid_21626024 = validateParameter(valid_21626024, JString, required = true,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "Timestamp", valid_21626024
  var valid_21626025 = query.getOrDefault("Operation")
  valid_21626025 = validateParameter(valid_21626025, JString, required = true,
                                   default = newJString("CancelJob"))
  if valid_21626025 != nil:
    section.add "Operation", valid_21626025
  var valid_21626026 = query.getOrDefault("SignatureVersion")
  valid_21626026 = validateParameter(valid_21626026, JString, required = true,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "SignatureVersion", valid_21626026
  var valid_21626027 = query.getOrDefault("AWSAccessKeyId")
  valid_21626027 = validateParameter(valid_21626027, JString, required = true,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "AWSAccessKeyId", valid_21626027
  var valid_21626028 = query.getOrDefault("Version")
  valid_21626028 = validateParameter(valid_21626028, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626028 != nil:
    section.add "Version", valid_21626028
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_21626029 = formData.getOrDefault("JobId")
  valid_21626029 = validateParameter(valid_21626029, JString, required = true,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "JobId", valid_21626029
  var valid_21626030 = formData.getOrDefault("APIVersion")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "APIVersion", valid_21626030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626031: Call_PostCancelJob_21626018; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_21626031.validator(path, query, header, formData, body, _)
  let scheme = call_21626031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626031.makeUrl(scheme.get, call_21626031.host, call_21626031.base,
                               call_21626031.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626031, uri, valid, _)

proc call*(call_21626032: Call_PostCancelJob_21626018; SignatureMethod: string;
          Signature: string; Timestamp: string; JobId: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "CancelJob"; Operation: string = "CancelJob";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_21626033 = newJObject()
  var formData_21626034 = newJObject()
  add(query_21626033, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626033, "Signature", newJString(Signature))
  add(query_21626033, "Action", newJString(Action))
  add(query_21626033, "Timestamp", newJString(Timestamp))
  add(formData_21626034, "JobId", newJString(JobId))
  add(query_21626033, "Operation", newJString(Operation))
  add(query_21626033, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626033, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626033, "Version", newJString(Version))
  add(formData_21626034, "APIVersion", newJString(APIVersion))
  result = call_21626032.call(nil, query_21626033, nil, formData_21626034, nil)

var postCancelJob* = Call_PostCancelJob_21626018(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_21626019, base: "/",
    makeUrl: url_PostCancelJob_21626020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_21625762 = ref object of OpenApiRestCall_21625418
proc url_GetCancelJob_21625764(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCancelJob_21625763(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21625865 = query.getOrDefault("SignatureMethod")
  valid_21625865 = validateParameter(valid_21625865, JString, required = true,
                                   default = nil)
  if valid_21625865 != nil:
    section.add "SignatureMethod", valid_21625865
  var valid_21625866 = query.getOrDefault("JobId")
  valid_21625866 = validateParameter(valid_21625866, JString, required = true,
                                   default = nil)
  if valid_21625866 != nil:
    section.add "JobId", valid_21625866
  var valid_21625867 = query.getOrDefault("APIVersion")
  valid_21625867 = validateParameter(valid_21625867, JString, required = false,
                                   default = nil)
  if valid_21625867 != nil:
    section.add "APIVersion", valid_21625867
  var valid_21625868 = query.getOrDefault("Signature")
  valid_21625868 = validateParameter(valid_21625868, JString, required = true,
                                   default = nil)
  if valid_21625868 != nil:
    section.add "Signature", valid_21625868
  var valid_21625883 = query.getOrDefault("Action")
  valid_21625883 = validateParameter(valid_21625883, JString, required = true,
                                   default = newJString("CancelJob"))
  if valid_21625883 != nil:
    section.add "Action", valid_21625883
  var valid_21625884 = query.getOrDefault("Timestamp")
  valid_21625884 = validateParameter(valid_21625884, JString, required = true,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "Timestamp", valid_21625884
  var valid_21625885 = query.getOrDefault("Operation")
  valid_21625885 = validateParameter(valid_21625885, JString, required = true,
                                   default = newJString("CancelJob"))
  if valid_21625885 != nil:
    section.add "Operation", valid_21625885
  var valid_21625886 = query.getOrDefault("SignatureVersion")
  valid_21625886 = validateParameter(valid_21625886, JString, required = true,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "SignatureVersion", valid_21625886
  var valid_21625887 = query.getOrDefault("AWSAccessKeyId")
  valid_21625887 = validateParameter(valid_21625887, JString, required = true,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "AWSAccessKeyId", valid_21625887
  var valid_21625888 = query.getOrDefault("Version")
  valid_21625888 = validateParameter(valid_21625888, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21625888 != nil:
    section.add "Version", valid_21625888
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625913: Call_GetCancelJob_21625762; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_21625913.validator(path, query, header, formData, body, _)
  let scheme = call_21625913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625913.makeUrl(scheme.get, call_21625913.host, call_21625913.base,
                               call_21625913.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625913, uri, valid, _)

proc call*(call_21625976: Call_GetCancelJob_21625762; SignatureMethod: string;
          JobId: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; APIVersion: string = "";
          Action: string = "CancelJob"; Operation: string = "CancelJob";
          Version: string = "2010-06-01"): Recallable =
  ## getCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   SignatureMethod: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_21625978 = newJObject()
  add(query_21625978, "SignatureMethod", newJString(SignatureMethod))
  add(query_21625978, "JobId", newJString(JobId))
  add(query_21625978, "APIVersion", newJString(APIVersion))
  add(query_21625978, "Signature", newJString(Signature))
  add(query_21625978, "Action", newJString(Action))
  add(query_21625978, "Timestamp", newJString(Timestamp))
  add(query_21625978, "Operation", newJString(Operation))
  add(query_21625978, "SignatureVersion", newJString(SignatureVersion))
  add(query_21625978, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21625978, "Version", newJString(Version))
  result = call_21625976.call(nil, query_21625978, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_21625762(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_21625763, base: "/", makeUrl: url_GetCancelJob_21625764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_21626054 = ref object of OpenApiRestCall_21625418
proc url_PostCreateJob_21626056(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateJob_21626055(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626057 = query.getOrDefault("SignatureMethod")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "SignatureMethod", valid_21626057
  var valid_21626058 = query.getOrDefault("Signature")
  valid_21626058 = validateParameter(valid_21626058, JString, required = true,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "Signature", valid_21626058
  var valid_21626059 = query.getOrDefault("Action")
  valid_21626059 = validateParameter(valid_21626059, JString, required = true,
                                   default = newJString("CreateJob"))
  if valid_21626059 != nil:
    section.add "Action", valid_21626059
  var valid_21626060 = query.getOrDefault("Timestamp")
  valid_21626060 = validateParameter(valid_21626060, JString, required = true,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "Timestamp", valid_21626060
  var valid_21626061 = query.getOrDefault("Operation")
  valid_21626061 = validateParameter(valid_21626061, JString, required = true,
                                   default = newJString("CreateJob"))
  if valid_21626061 != nil:
    section.add "Operation", valid_21626061
  var valid_21626062 = query.getOrDefault("SignatureVersion")
  valid_21626062 = validateParameter(valid_21626062, JString, required = true,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "SignatureVersion", valid_21626062
  var valid_21626063 = query.getOrDefault("AWSAccessKeyId")
  valid_21626063 = validateParameter(valid_21626063, JString, required = true,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "AWSAccessKeyId", valid_21626063
  var valid_21626064 = query.getOrDefault("Version")
  valid_21626064 = validateParameter(valid_21626064, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626064 != nil:
    section.add "Version", valid_21626064
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   ManifestAddendum: JString
  ##                   : For internal use only.
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  var valid_21626065 = formData.getOrDefault("ManifestAddendum")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "ManifestAddendum", valid_21626065
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_21626066 = formData.getOrDefault("Manifest")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "Manifest", valid_21626066
  var valid_21626067 = formData.getOrDefault("JobType")
  valid_21626067 = validateParameter(valid_21626067, JString, required = true,
                                   default = newJString("Import"))
  if valid_21626067 != nil:
    section.add "JobType", valid_21626067
  var valid_21626068 = formData.getOrDefault("ValidateOnly")
  valid_21626068 = validateParameter(valid_21626068, JBool, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "ValidateOnly", valid_21626068
  var valid_21626069 = formData.getOrDefault("APIVersion")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "APIVersion", valid_21626069
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626070: Call_PostCreateJob_21626054; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_21626070.validator(path, query, header, formData, body, _)
  let scheme = call_21626070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626070.makeUrl(scheme.get, call_21626070.host, call_21626070.base,
                               call_21626070.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626070, uri, valid, _)

proc call*(call_21626071: Call_PostCreateJob_21626054; SignatureMethod: string;
          Signature: string; Manifest: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; ValidateOnly: bool;
          ManifestAddendum: string = ""; JobType: string = "Import";
          Action: string = "CreateJob"; Operation: string = "CreateJob";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   SignatureMethod: string (required)
  ##   ManifestAddendum: string
  ##                   : For internal use only.
  ##   Signature: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_21626072 = newJObject()
  var formData_21626073 = newJObject()
  add(query_21626072, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626073, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_21626072, "Signature", newJString(Signature))
  add(formData_21626073, "Manifest", newJString(Manifest))
  add(formData_21626073, "JobType", newJString(JobType))
  add(query_21626072, "Action", newJString(Action))
  add(query_21626072, "Timestamp", newJString(Timestamp))
  add(query_21626072, "Operation", newJString(Operation))
  add(query_21626072, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626072, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626072, "Version", newJString(Version))
  add(formData_21626073, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_21626073, "APIVersion", newJString(APIVersion))
  result = call_21626071.call(nil, query_21626072, nil, formData_21626073, nil)

var postCreateJob* = Call_PostCreateJob_21626054(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_21626055, base: "/",
    makeUrl: url_PostCreateJob_21626056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_21626035 = ref object of OpenApiRestCall_21625418
proc url_GetCreateJob_21626037(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateJob_21626036(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: JString (required)
  ##   ManifestAddendum: JString
  ##                   : For internal use only.
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626038 = query.getOrDefault("SignatureMethod")
  valid_21626038 = validateParameter(valid_21626038, JString, required = true,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "SignatureMethod", valid_21626038
  var valid_21626039 = query.getOrDefault("Manifest")
  valid_21626039 = validateParameter(valid_21626039, JString, required = true,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "Manifest", valid_21626039
  var valid_21626040 = query.getOrDefault("APIVersion")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "APIVersion", valid_21626040
  var valid_21626041 = query.getOrDefault("Signature")
  valid_21626041 = validateParameter(valid_21626041, JString, required = true,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "Signature", valid_21626041
  var valid_21626042 = query.getOrDefault("Action")
  valid_21626042 = validateParameter(valid_21626042, JString, required = true,
                                   default = newJString("CreateJob"))
  if valid_21626042 != nil:
    section.add "Action", valid_21626042
  var valid_21626043 = query.getOrDefault("JobType")
  valid_21626043 = validateParameter(valid_21626043, JString, required = true,
                                   default = newJString("Import"))
  if valid_21626043 != nil:
    section.add "JobType", valid_21626043
  var valid_21626044 = query.getOrDefault("ValidateOnly")
  valid_21626044 = validateParameter(valid_21626044, JBool, required = true,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "ValidateOnly", valid_21626044
  var valid_21626045 = query.getOrDefault("Timestamp")
  valid_21626045 = validateParameter(valid_21626045, JString, required = true,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "Timestamp", valid_21626045
  var valid_21626046 = query.getOrDefault("ManifestAddendum")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "ManifestAddendum", valid_21626046
  var valid_21626047 = query.getOrDefault("Operation")
  valid_21626047 = validateParameter(valid_21626047, JString, required = true,
                                   default = newJString("CreateJob"))
  if valid_21626047 != nil:
    section.add "Operation", valid_21626047
  var valid_21626048 = query.getOrDefault("SignatureVersion")
  valid_21626048 = validateParameter(valid_21626048, JString, required = true,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "SignatureVersion", valid_21626048
  var valid_21626049 = query.getOrDefault("AWSAccessKeyId")
  valid_21626049 = validateParameter(valid_21626049, JString, required = true,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "AWSAccessKeyId", valid_21626049
  var valid_21626050 = query.getOrDefault("Version")
  valid_21626050 = validateParameter(valid_21626050, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626050 != nil:
    section.add "Version", valid_21626050
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626051: Call_GetCreateJob_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_21626051.validator(path, query, header, formData, body, _)
  let scheme = call_21626051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626051.makeUrl(scheme.get, call_21626051.host, call_21626051.base,
                               call_21626051.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626051, uri, valid, _)

proc call*(call_21626052: Call_GetCreateJob_21626035; SignatureMethod: string;
          Manifest: string; Signature: string; ValidateOnly: bool; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; APIVersion: string = "";
          Action: string = "CreateJob"; JobType: string = "Import";
          ManifestAddendum: string = ""; Operation: string = "CreateJob";
          Version: string = "2010-06-01"): Recallable =
  ## getCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   SignatureMethod: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: string (required)
  ##   ManifestAddendum: string
  ##                   : For internal use only.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_21626053 = newJObject()
  add(query_21626053, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626053, "Manifest", newJString(Manifest))
  add(query_21626053, "APIVersion", newJString(APIVersion))
  add(query_21626053, "Signature", newJString(Signature))
  add(query_21626053, "Action", newJString(Action))
  add(query_21626053, "JobType", newJString(JobType))
  add(query_21626053, "ValidateOnly", newJBool(ValidateOnly))
  add(query_21626053, "Timestamp", newJString(Timestamp))
  add(query_21626053, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_21626053, "Operation", newJString(Operation))
  add(query_21626053, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626053, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626053, "Version", newJString(Version))
  result = call_21626052.call(nil, query_21626053, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_21626035(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_21626036, base: "/", makeUrl: url_GetCreateJob_21626037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_21626100 = ref object of OpenApiRestCall_21625418
proc url_PostGetShippingLabel_21626102(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetShippingLabel_21626101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626103 = query.getOrDefault("SignatureMethod")
  valid_21626103 = validateParameter(valid_21626103, JString, required = true,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "SignatureMethod", valid_21626103
  var valid_21626104 = query.getOrDefault("Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = true,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "Signature", valid_21626104
  var valid_21626105 = query.getOrDefault("Action")
  valid_21626105 = validateParameter(valid_21626105, JString, required = true,
                                   default = newJString("GetShippingLabel"))
  if valid_21626105 != nil:
    section.add "Action", valid_21626105
  var valid_21626106 = query.getOrDefault("Timestamp")
  valid_21626106 = validateParameter(valid_21626106, JString, required = true,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "Timestamp", valid_21626106
  var valid_21626107 = query.getOrDefault("Operation")
  valid_21626107 = validateParameter(valid_21626107, JString, required = true,
                                   default = newJString("GetShippingLabel"))
  if valid_21626107 != nil:
    section.add "Operation", valid_21626107
  var valid_21626108 = query.getOrDefault("SignatureVersion")
  valid_21626108 = validateParameter(valid_21626108, JString, required = true,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "SignatureVersion", valid_21626108
  var valid_21626109 = query.getOrDefault("AWSAccessKeyId")
  valid_21626109 = validateParameter(valid_21626109, JString, required = true,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "AWSAccessKeyId", valid_21626109
  var valid_21626110 = query.getOrDefault("Version")
  valid_21626110 = validateParameter(valid_21626110, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626110 != nil:
    section.add "Version", valid_21626110
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   company: JString
  ##          : Specifies the name of the company that will ship this package.
  ##   stateOrProvince: JString
  ##                  : Specifies the name of your state or your province for the return address.
  ##   street1: JString
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   name: JString
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   street3: JString
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   city: JString
  ##       : Specifies the name of your city for the return address.
  ##   postalCode: JString
  ##             : Specifies the postal code for the return address.
  ##   phoneNumber: JString
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   street2: JString
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   country: JString
  ##          : Specifies the name of your country for the return address.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   jobIds: JArray (required)
  section = newJObject()
  var valid_21626111 = formData.getOrDefault("company")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "company", valid_21626111
  var valid_21626112 = formData.getOrDefault("stateOrProvince")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "stateOrProvince", valid_21626112
  var valid_21626113 = formData.getOrDefault("street1")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "street1", valid_21626113
  var valid_21626114 = formData.getOrDefault("name")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "name", valid_21626114
  var valid_21626115 = formData.getOrDefault("street3")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "street3", valid_21626115
  var valid_21626116 = formData.getOrDefault("city")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "city", valid_21626116
  var valid_21626117 = formData.getOrDefault("postalCode")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "postalCode", valid_21626117
  var valid_21626118 = formData.getOrDefault("phoneNumber")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "phoneNumber", valid_21626118
  var valid_21626119 = formData.getOrDefault("street2")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "street2", valid_21626119
  var valid_21626120 = formData.getOrDefault("country")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "country", valid_21626120
  var valid_21626121 = formData.getOrDefault("APIVersion")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "APIVersion", valid_21626121
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_21626122 = formData.getOrDefault("jobIds")
  valid_21626122 = validateParameter(valid_21626122, JArray, required = true,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "jobIds", valid_21626122
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626123: Call_PostGetShippingLabel_21626100; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_21626123.validator(path, query, header, formData, body, _)
  let scheme = call_21626123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626123.makeUrl(scheme.get, call_21626123.host, call_21626123.base,
                               call_21626123.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626123, uri, valid, _)

proc call*(call_21626124: Call_PostGetShippingLabel_21626100;
          SignatureMethod: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; jobIds: JsonNode;
          company: string = ""; stateOrProvince: string = ""; street1: string = "";
          name: string = ""; street3: string = ""; Action: string = "GetShippingLabel";
          city: string = ""; postalCode: string = "";
          Operation: string = "GetShippingLabel"; phoneNumber: string = "";
          street2: string = ""; Version: string = "2010-06-01"; country: string = "";
          APIVersion: string = ""): Recallable =
  ## postGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   company: string
  ##          : Specifies the name of the company that will ship this package.
  ##   SignatureMethod: string (required)
  ##   stateOrProvince: string
  ##                  : Specifies the name of your state or your province for the return address.
  ##   Signature: string (required)
  ##   street1: string
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   name: string
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   street3: string
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   Action: string (required)
  ##   city: string
  ##       : Specifies the name of your city for the return address.
  ##   Timestamp: string (required)
  ##   postalCode: string
  ##             : Specifies the postal code for the return address.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   phoneNumber: string
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   AWSAccessKeyId: string (required)
  ##   street2: string
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   Version: string (required)
  ##   country: string
  ##          : Specifies the name of your country for the return address.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   jobIds: JArray (required)
  var query_21626125 = newJObject()
  var formData_21626126 = newJObject()
  add(formData_21626126, "company", newJString(company))
  add(query_21626125, "SignatureMethod", newJString(SignatureMethod))
  add(formData_21626126, "stateOrProvince", newJString(stateOrProvince))
  add(query_21626125, "Signature", newJString(Signature))
  add(formData_21626126, "street1", newJString(street1))
  add(formData_21626126, "name", newJString(name))
  add(formData_21626126, "street3", newJString(street3))
  add(query_21626125, "Action", newJString(Action))
  add(formData_21626126, "city", newJString(city))
  add(query_21626125, "Timestamp", newJString(Timestamp))
  add(formData_21626126, "postalCode", newJString(postalCode))
  add(query_21626125, "Operation", newJString(Operation))
  add(query_21626125, "SignatureVersion", newJString(SignatureVersion))
  add(formData_21626126, "phoneNumber", newJString(phoneNumber))
  add(query_21626125, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_21626126, "street2", newJString(street2))
  add(query_21626125, "Version", newJString(Version))
  add(formData_21626126, "country", newJString(country))
  add(formData_21626126, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_21626126.add "jobIds", jobIds
  result = call_21626124.call(nil, query_21626125, nil, formData_21626126, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_21626100(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_21626101, base: "/",
    makeUrl: url_PostGetShippingLabel_21626102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_21626074 = ref object of OpenApiRestCall_21625418
proc url_GetGetShippingLabel_21626076(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetShippingLabel_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   city: JString
  ##       : Specifies the name of your city for the return address.
  ##   country: JString
  ##          : Specifies the name of your country for the return address.
  ##   stateOrProvince: JString
  ##                  : Specifies the name of your state or your province for the return address.
  ##   company: JString
  ##          : Specifies the name of the company that will ship this package.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   phoneNumber: JString
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   street1: JString
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   Signature: JString (required)
  ##   street3: JString
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   Action: JString (required)
  ##   name: JString
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   jobIds: JArray (required)
  ##   AWSAccessKeyId: JString (required)
  ##   street2: JString
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   postalCode: JString
  ##             : Specifies the postal code for the return address.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626077 = query.getOrDefault("SignatureMethod")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "SignatureMethod", valid_21626077
  var valid_21626078 = query.getOrDefault("city")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "city", valid_21626078
  var valid_21626079 = query.getOrDefault("country")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "country", valid_21626079
  var valid_21626080 = query.getOrDefault("stateOrProvince")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "stateOrProvince", valid_21626080
  var valid_21626081 = query.getOrDefault("company")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "company", valid_21626081
  var valid_21626082 = query.getOrDefault("APIVersion")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "APIVersion", valid_21626082
  var valid_21626083 = query.getOrDefault("phoneNumber")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "phoneNumber", valid_21626083
  var valid_21626084 = query.getOrDefault("street1")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "street1", valid_21626084
  var valid_21626085 = query.getOrDefault("Signature")
  valid_21626085 = validateParameter(valid_21626085, JString, required = true,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "Signature", valid_21626085
  var valid_21626086 = query.getOrDefault("street3")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "street3", valid_21626086
  var valid_21626087 = query.getOrDefault("Action")
  valid_21626087 = validateParameter(valid_21626087, JString, required = true,
                                   default = newJString("GetShippingLabel"))
  if valid_21626087 != nil:
    section.add "Action", valid_21626087
  var valid_21626088 = query.getOrDefault("name")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "name", valid_21626088
  var valid_21626089 = query.getOrDefault("Timestamp")
  valid_21626089 = validateParameter(valid_21626089, JString, required = true,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "Timestamp", valid_21626089
  var valid_21626090 = query.getOrDefault("Operation")
  valid_21626090 = validateParameter(valid_21626090, JString, required = true,
                                   default = newJString("GetShippingLabel"))
  if valid_21626090 != nil:
    section.add "Operation", valid_21626090
  var valid_21626091 = query.getOrDefault("SignatureVersion")
  valid_21626091 = validateParameter(valid_21626091, JString, required = true,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "SignatureVersion", valid_21626091
  var valid_21626092 = query.getOrDefault("jobIds")
  valid_21626092 = validateParameter(valid_21626092, JArray, required = true,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "jobIds", valid_21626092
  var valid_21626093 = query.getOrDefault("AWSAccessKeyId")
  valid_21626093 = validateParameter(valid_21626093, JString, required = true,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "AWSAccessKeyId", valid_21626093
  var valid_21626094 = query.getOrDefault("street2")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "street2", valid_21626094
  var valid_21626095 = query.getOrDefault("postalCode")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "postalCode", valid_21626095
  var valid_21626096 = query.getOrDefault("Version")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626096 != nil:
    section.add "Version", valid_21626096
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626097: Call_GetGetShippingLabel_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_21626097.validator(path, query, header, formData, body, _)
  let scheme = call_21626097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626097.makeUrl(scheme.get, call_21626097.host, call_21626097.base,
                               call_21626097.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626097, uri, valid, _)

proc call*(call_21626098: Call_GetGetShippingLabel_21626074;
          SignatureMethod: string; Signature: string; Timestamp: string;
          SignatureVersion: string; jobIds: JsonNode; AWSAccessKeyId: string;
          city: string = ""; country: string = ""; stateOrProvince: string = "";
          company: string = ""; APIVersion: string = ""; phoneNumber: string = "";
          street1: string = ""; street3: string = "";
          Action: string = "GetShippingLabel"; name: string = "";
          Operation: string = "GetShippingLabel"; street2: string = "";
          postalCode: string = ""; Version: string = "2010-06-01"): Recallable =
  ## getGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   SignatureMethod: string (required)
  ##   city: string
  ##       : Specifies the name of your city for the return address.
  ##   country: string
  ##          : Specifies the name of your country for the return address.
  ##   stateOrProvince: string
  ##                  : Specifies the name of your state or your province for the return address.
  ##   company: string
  ##          : Specifies the name of the company that will ship this package.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   phoneNumber: string
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   street1: string
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   Signature: string (required)
  ##   street3: string
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   Action: string (required)
  ##   name: string
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   jobIds: JArray (required)
  ##   AWSAccessKeyId: string (required)
  ##   street2: string
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   postalCode: string
  ##             : Specifies the postal code for the return address.
  ##   Version: string (required)
  var query_21626099 = newJObject()
  add(query_21626099, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626099, "city", newJString(city))
  add(query_21626099, "country", newJString(country))
  add(query_21626099, "stateOrProvince", newJString(stateOrProvince))
  add(query_21626099, "company", newJString(company))
  add(query_21626099, "APIVersion", newJString(APIVersion))
  add(query_21626099, "phoneNumber", newJString(phoneNumber))
  add(query_21626099, "street1", newJString(street1))
  add(query_21626099, "Signature", newJString(Signature))
  add(query_21626099, "street3", newJString(street3))
  add(query_21626099, "Action", newJString(Action))
  add(query_21626099, "name", newJString(name))
  add(query_21626099, "Timestamp", newJString(Timestamp))
  add(query_21626099, "Operation", newJString(Operation))
  add(query_21626099, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_21626099.add "jobIds", jobIds
  add(query_21626099, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626099, "street2", newJString(street2))
  add(query_21626099, "postalCode", newJString(postalCode))
  add(query_21626099, "Version", newJString(Version))
  result = call_21626098.call(nil, query_21626099, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_21626074(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_21626075, base: "/",
    makeUrl: url_GetGetShippingLabel_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_21626143 = ref object of OpenApiRestCall_21625418
proc url_PostGetStatus_21626145(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetStatus_21626144(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626146 = query.getOrDefault("SignatureMethod")
  valid_21626146 = validateParameter(valid_21626146, JString, required = true,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "SignatureMethod", valid_21626146
  var valid_21626147 = query.getOrDefault("Signature")
  valid_21626147 = validateParameter(valid_21626147, JString, required = true,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "Signature", valid_21626147
  var valid_21626148 = query.getOrDefault("Action")
  valid_21626148 = validateParameter(valid_21626148, JString, required = true,
                                   default = newJString("GetStatus"))
  if valid_21626148 != nil:
    section.add "Action", valid_21626148
  var valid_21626149 = query.getOrDefault("Timestamp")
  valid_21626149 = validateParameter(valid_21626149, JString, required = true,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "Timestamp", valid_21626149
  var valid_21626150 = query.getOrDefault("Operation")
  valid_21626150 = validateParameter(valid_21626150, JString, required = true,
                                   default = newJString("GetStatus"))
  if valid_21626150 != nil:
    section.add "Operation", valid_21626150
  var valid_21626151 = query.getOrDefault("SignatureVersion")
  valid_21626151 = validateParameter(valid_21626151, JString, required = true,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "SignatureVersion", valid_21626151
  var valid_21626152 = query.getOrDefault("AWSAccessKeyId")
  valid_21626152 = validateParameter(valid_21626152, JString, required = true,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "AWSAccessKeyId", valid_21626152
  var valid_21626153 = query.getOrDefault("Version")
  valid_21626153 = validateParameter(valid_21626153, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626153 != nil:
    section.add "Version", valid_21626153
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_21626154 = formData.getOrDefault("JobId")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "JobId", valid_21626154
  var valid_21626155 = formData.getOrDefault("APIVersion")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "APIVersion", valid_21626155
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626156: Call_PostGetStatus_21626143; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_21626156.validator(path, query, header, formData, body, _)
  let scheme = call_21626156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626156.makeUrl(scheme.get, call_21626156.host, call_21626156.base,
                               call_21626156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626156, uri, valid, _)

proc call*(call_21626157: Call_PostGetStatus_21626143; SignatureMethod: string;
          Signature: string; Timestamp: string; JobId: string;
          SignatureVersion: string; AWSAccessKeyId: string;
          Action: string = "GetStatus"; Operation: string = "GetStatus";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_21626158 = newJObject()
  var formData_21626159 = newJObject()
  add(query_21626158, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626158, "Signature", newJString(Signature))
  add(query_21626158, "Action", newJString(Action))
  add(query_21626158, "Timestamp", newJString(Timestamp))
  add(formData_21626159, "JobId", newJString(JobId))
  add(query_21626158, "Operation", newJString(Operation))
  add(query_21626158, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626158, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626158, "Version", newJString(Version))
  add(formData_21626159, "APIVersion", newJString(APIVersion))
  result = call_21626157.call(nil, query_21626158, nil, formData_21626159, nil)

var postGetStatus* = Call_PostGetStatus_21626143(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_21626144, base: "/",
    makeUrl: url_PostGetStatus_21626145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_21626127 = ref object of OpenApiRestCall_21625418
proc url_GetGetStatus_21626129(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetStatus_21626128(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626130 = query.getOrDefault("SignatureMethod")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "SignatureMethod", valid_21626130
  var valid_21626131 = query.getOrDefault("JobId")
  valid_21626131 = validateParameter(valid_21626131, JString, required = true,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "JobId", valid_21626131
  var valid_21626132 = query.getOrDefault("APIVersion")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "APIVersion", valid_21626132
  var valid_21626133 = query.getOrDefault("Signature")
  valid_21626133 = validateParameter(valid_21626133, JString, required = true,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "Signature", valid_21626133
  var valid_21626134 = query.getOrDefault("Action")
  valid_21626134 = validateParameter(valid_21626134, JString, required = true,
                                   default = newJString("GetStatus"))
  if valid_21626134 != nil:
    section.add "Action", valid_21626134
  var valid_21626135 = query.getOrDefault("Timestamp")
  valid_21626135 = validateParameter(valid_21626135, JString, required = true,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "Timestamp", valid_21626135
  var valid_21626136 = query.getOrDefault("Operation")
  valid_21626136 = validateParameter(valid_21626136, JString, required = true,
                                   default = newJString("GetStatus"))
  if valid_21626136 != nil:
    section.add "Operation", valid_21626136
  var valid_21626137 = query.getOrDefault("SignatureVersion")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "SignatureVersion", valid_21626137
  var valid_21626138 = query.getOrDefault("AWSAccessKeyId")
  valid_21626138 = validateParameter(valid_21626138, JString, required = true,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "AWSAccessKeyId", valid_21626138
  var valid_21626139 = query.getOrDefault("Version")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626139 != nil:
    section.add "Version", valid_21626139
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626140: Call_GetGetStatus_21626127; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_21626140.validator(path, query, header, formData, body, _)
  let scheme = call_21626140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626140.makeUrl(scheme.get, call_21626140.host, call_21626140.base,
                               call_21626140.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626140, uri, valid, _)

proc call*(call_21626141: Call_GetGetStatus_21626127; SignatureMethod: string;
          JobId: string; Signature: string; Timestamp: string;
          SignatureVersion: string; AWSAccessKeyId: string; APIVersion: string = "";
          Action: string = "GetStatus"; Operation: string = "GetStatus";
          Version: string = "2010-06-01"): Recallable =
  ## getGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   SignatureMethod: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_21626142 = newJObject()
  add(query_21626142, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626142, "JobId", newJString(JobId))
  add(query_21626142, "APIVersion", newJString(APIVersion))
  add(query_21626142, "Signature", newJString(Signature))
  add(query_21626142, "Action", newJString(Action))
  add(query_21626142, "Timestamp", newJString(Timestamp))
  add(query_21626142, "Operation", newJString(Operation))
  add(query_21626142, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626142, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626142, "Version", newJString(Version))
  result = call_21626141.call(nil, query_21626142, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_21626127(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_21626128, base: "/", makeUrl: url_GetGetStatus_21626129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_21626177 = ref object of OpenApiRestCall_21625418
proc url_PostListJobs_21626179(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListJobs_21626178(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626180 = query.getOrDefault("SignatureMethod")
  valid_21626180 = validateParameter(valid_21626180, JString, required = true,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "SignatureMethod", valid_21626180
  var valid_21626181 = query.getOrDefault("Signature")
  valid_21626181 = validateParameter(valid_21626181, JString, required = true,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "Signature", valid_21626181
  var valid_21626182 = query.getOrDefault("Action")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = newJString("ListJobs"))
  if valid_21626182 != nil:
    section.add "Action", valid_21626182
  var valid_21626183 = query.getOrDefault("Timestamp")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "Timestamp", valid_21626183
  var valid_21626184 = query.getOrDefault("Operation")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true,
                                   default = newJString("ListJobs"))
  if valid_21626184 != nil:
    section.add "Operation", valid_21626184
  var valid_21626185 = query.getOrDefault("SignatureVersion")
  valid_21626185 = validateParameter(valid_21626185, JString, required = true,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "SignatureVersion", valid_21626185
  var valid_21626186 = query.getOrDefault("AWSAccessKeyId")
  valid_21626186 = validateParameter(valid_21626186, JString, required = true,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "AWSAccessKeyId", valid_21626186
  var valid_21626187 = query.getOrDefault("Version")
  valid_21626187 = validateParameter(valid_21626187, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626187 != nil:
    section.add "Version", valid_21626187
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   MaxJobs: JInt
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  var valid_21626188 = formData.getOrDefault("Marker")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "Marker", valid_21626188
  var valid_21626189 = formData.getOrDefault("MaxJobs")
  valid_21626189 = validateParameter(valid_21626189, JInt, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "MaxJobs", valid_21626189
  var valid_21626190 = formData.getOrDefault("APIVersion")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "APIVersion", valid_21626190
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626191: Call_PostListJobs_21626177; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_21626191.validator(path, query, header, formData, body, _)
  let scheme = call_21626191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626191.makeUrl(scheme.get, call_21626191.host, call_21626191.base,
                               call_21626191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626191, uri, valid, _)

proc call*(call_21626192: Call_PostListJobs_21626177; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; Marker: string = ""; Action: string = "ListJobs";
          MaxJobs: int = 0; Operation: string = "ListJobs";
          Version: string = "2010-06-01"; APIVersion: string = ""): Recallable =
  ## postListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Marker: string
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Action: string (required)
  ##   MaxJobs: int
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_21626193 = newJObject()
  var formData_21626194 = newJObject()
  add(query_21626193, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626193, "Signature", newJString(Signature))
  add(formData_21626194, "Marker", newJString(Marker))
  add(query_21626193, "Action", newJString(Action))
  add(formData_21626194, "MaxJobs", newJInt(MaxJobs))
  add(query_21626193, "Timestamp", newJString(Timestamp))
  add(query_21626193, "Operation", newJString(Operation))
  add(query_21626193, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626193, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626193, "Version", newJString(Version))
  add(formData_21626194, "APIVersion", newJString(APIVersion))
  result = call_21626192.call(nil, query_21626193, nil, formData_21626194, nil)

var postListJobs* = Call_PostListJobs_21626177(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_21626178, base: "/", makeUrl: url_PostListJobs_21626179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_21626160 = ref object of OpenApiRestCall_21625418
proc url_GetListJobs_21626162(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListJobs_21626161(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   MaxJobs: JInt
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Action: JString (required)
  ##   Marker: JString
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626163 = query.getOrDefault("SignatureMethod")
  valid_21626163 = validateParameter(valid_21626163, JString, required = true,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "SignatureMethod", valid_21626163
  var valid_21626164 = query.getOrDefault("APIVersion")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "APIVersion", valid_21626164
  var valid_21626165 = query.getOrDefault("Signature")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "Signature", valid_21626165
  var valid_21626166 = query.getOrDefault("MaxJobs")
  valid_21626166 = validateParameter(valid_21626166, JInt, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "MaxJobs", valid_21626166
  var valid_21626167 = query.getOrDefault("Action")
  valid_21626167 = validateParameter(valid_21626167, JString, required = true,
                                   default = newJString("ListJobs"))
  if valid_21626167 != nil:
    section.add "Action", valid_21626167
  var valid_21626168 = query.getOrDefault("Marker")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "Marker", valid_21626168
  var valid_21626169 = query.getOrDefault("Timestamp")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "Timestamp", valid_21626169
  var valid_21626170 = query.getOrDefault("Operation")
  valid_21626170 = validateParameter(valid_21626170, JString, required = true,
                                   default = newJString("ListJobs"))
  if valid_21626170 != nil:
    section.add "Operation", valid_21626170
  var valid_21626171 = query.getOrDefault("SignatureVersion")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "SignatureVersion", valid_21626171
  var valid_21626172 = query.getOrDefault("AWSAccessKeyId")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "AWSAccessKeyId", valid_21626172
  var valid_21626173 = query.getOrDefault("Version")
  valid_21626173 = validateParameter(valid_21626173, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626173 != nil:
    section.add "Version", valid_21626173
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626174: Call_GetListJobs_21626160; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_21626174.validator(path, query, header, formData, body, _)
  let scheme = call_21626174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626174.makeUrl(scheme.get, call_21626174.host, call_21626174.base,
                               call_21626174.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626174, uri, valid, _)

proc call*(call_21626175: Call_GetListJobs_21626160; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; APIVersion: string = ""; MaxJobs: int = 0;
          Action: string = "ListJobs"; Marker: string = "";
          Operation: string = "ListJobs"; Version: string = "2010-06-01"): Recallable =
  ## getListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   SignatureMethod: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   MaxJobs: int
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Action: string (required)
  ##   Marker: string
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_21626176 = newJObject()
  add(query_21626176, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626176, "APIVersion", newJString(APIVersion))
  add(query_21626176, "Signature", newJString(Signature))
  add(query_21626176, "MaxJobs", newJInt(MaxJobs))
  add(query_21626176, "Action", newJString(Action))
  add(query_21626176, "Marker", newJString(Marker))
  add(query_21626176, "Timestamp", newJString(Timestamp))
  add(query_21626176, "Operation", newJString(Operation))
  add(query_21626176, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626176, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626176, "Version", newJString(Version))
  result = call_21626175.call(nil, query_21626176, nil, nil, nil)

var getListJobs* = Call_GetListJobs_21626160(name: "getListJobs",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_GetListJobs_21626161, base: "/", makeUrl: url_GetListJobs_21626162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_21626214 = ref object of OpenApiRestCall_21625418
proc url_PostUpdateJob_21626216(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateJob_21626215(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626217 = query.getOrDefault("SignatureMethod")
  valid_21626217 = validateParameter(valid_21626217, JString, required = true,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "SignatureMethod", valid_21626217
  var valid_21626218 = query.getOrDefault("Signature")
  valid_21626218 = validateParameter(valid_21626218, JString, required = true,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "Signature", valid_21626218
  var valid_21626219 = query.getOrDefault("Action")
  valid_21626219 = validateParameter(valid_21626219, JString, required = true,
                                   default = newJString("UpdateJob"))
  if valid_21626219 != nil:
    section.add "Action", valid_21626219
  var valid_21626220 = query.getOrDefault("Timestamp")
  valid_21626220 = validateParameter(valid_21626220, JString, required = true,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "Timestamp", valid_21626220
  var valid_21626221 = query.getOrDefault("Operation")
  valid_21626221 = validateParameter(valid_21626221, JString, required = true,
                                   default = newJString("UpdateJob"))
  if valid_21626221 != nil:
    section.add "Operation", valid_21626221
  var valid_21626222 = query.getOrDefault("SignatureVersion")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "SignatureVersion", valid_21626222
  var valid_21626223 = query.getOrDefault("AWSAccessKeyId")
  valid_21626223 = validateParameter(valid_21626223, JString, required = true,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "AWSAccessKeyId", valid_21626223
  var valid_21626224 = query.getOrDefault("Version")
  valid_21626224 = validateParameter(valid_21626224, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626224 != nil:
    section.add "Version", valid_21626224
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_21626225 = formData.getOrDefault("Manifest")
  valid_21626225 = validateParameter(valid_21626225, JString, required = true,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "Manifest", valid_21626225
  var valid_21626226 = formData.getOrDefault("JobType")
  valid_21626226 = validateParameter(valid_21626226, JString, required = true,
                                   default = newJString("Import"))
  if valid_21626226 != nil:
    section.add "JobType", valid_21626226
  var valid_21626227 = formData.getOrDefault("JobId")
  valid_21626227 = validateParameter(valid_21626227, JString, required = true,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "JobId", valid_21626227
  var valid_21626228 = formData.getOrDefault("ValidateOnly")
  valid_21626228 = validateParameter(valid_21626228, JBool, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "ValidateOnly", valid_21626228
  var valid_21626229 = formData.getOrDefault("APIVersion")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "APIVersion", valid_21626229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626230: Call_PostUpdateJob_21626214; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_21626230.validator(path, query, header, formData, body, _)
  let scheme = call_21626230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626230.makeUrl(scheme.get, call_21626230.host, call_21626230.base,
                               call_21626230.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626230, uri, valid, _)

proc call*(call_21626231: Call_PostUpdateJob_21626214; SignatureMethod: string;
          Signature: string; Manifest: string; Timestamp: string; JobId: string;
          SignatureVersion: string; AWSAccessKeyId: string; ValidateOnly: bool;
          JobType: string = "Import"; Action: string = "UpdateJob";
          Operation: string = "UpdateJob"; Version: string = "2010-06-01";
          APIVersion: string = ""): Recallable =
  ## postUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   SignatureMethod: string (required)
  ##   Signature: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   Action: string (required)
  ##   Timestamp: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  var query_21626232 = newJObject()
  var formData_21626233 = newJObject()
  add(query_21626232, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626232, "Signature", newJString(Signature))
  add(formData_21626233, "Manifest", newJString(Manifest))
  add(formData_21626233, "JobType", newJString(JobType))
  add(query_21626232, "Action", newJString(Action))
  add(query_21626232, "Timestamp", newJString(Timestamp))
  add(formData_21626233, "JobId", newJString(JobId))
  add(query_21626232, "Operation", newJString(Operation))
  add(query_21626232, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626232, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626232, "Version", newJString(Version))
  add(formData_21626233, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_21626233, "APIVersion", newJString(APIVersion))
  result = call_21626231.call(nil, query_21626232, nil, formData_21626233, nil)

var postUpdateJob* = Call_PostUpdateJob_21626214(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_21626215, base: "/",
    makeUrl: url_PostUpdateJob_21626216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_21626195 = ref object of OpenApiRestCall_21625418
proc url_GetUpdateJob_21626197(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateJob_21626196(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SignatureMethod: JString (required)
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Signature: JString (required)
  ##   Action: JString (required)
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: JString (required)
  ##   Operation: JString (required)
  ##   SignatureVersion: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `SignatureMethod` field"
  var valid_21626198 = query.getOrDefault("SignatureMethod")
  valid_21626198 = validateParameter(valid_21626198, JString, required = true,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "SignatureMethod", valid_21626198
  var valid_21626199 = query.getOrDefault("Manifest")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "Manifest", valid_21626199
  var valid_21626200 = query.getOrDefault("JobId")
  valid_21626200 = validateParameter(valid_21626200, JString, required = true,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "JobId", valid_21626200
  var valid_21626201 = query.getOrDefault("APIVersion")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "APIVersion", valid_21626201
  var valid_21626202 = query.getOrDefault("Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = true,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "Signature", valid_21626202
  var valid_21626203 = query.getOrDefault("Action")
  valid_21626203 = validateParameter(valid_21626203, JString, required = true,
                                   default = newJString("UpdateJob"))
  if valid_21626203 != nil:
    section.add "Action", valid_21626203
  var valid_21626204 = query.getOrDefault("JobType")
  valid_21626204 = validateParameter(valid_21626204, JString, required = true,
                                   default = newJString("Import"))
  if valid_21626204 != nil:
    section.add "JobType", valid_21626204
  var valid_21626205 = query.getOrDefault("ValidateOnly")
  valid_21626205 = validateParameter(valid_21626205, JBool, required = true,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "ValidateOnly", valid_21626205
  var valid_21626206 = query.getOrDefault("Timestamp")
  valid_21626206 = validateParameter(valid_21626206, JString, required = true,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "Timestamp", valid_21626206
  var valid_21626207 = query.getOrDefault("Operation")
  valid_21626207 = validateParameter(valid_21626207, JString, required = true,
                                   default = newJString("UpdateJob"))
  if valid_21626207 != nil:
    section.add "Operation", valid_21626207
  var valid_21626208 = query.getOrDefault("SignatureVersion")
  valid_21626208 = validateParameter(valid_21626208, JString, required = true,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "SignatureVersion", valid_21626208
  var valid_21626209 = query.getOrDefault("AWSAccessKeyId")
  valid_21626209 = validateParameter(valid_21626209, JString, required = true,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "AWSAccessKeyId", valid_21626209
  var valid_21626210 = query.getOrDefault("Version")
  valid_21626210 = validateParameter(valid_21626210, JString, required = true,
                                   default = newJString("2010-06-01"))
  if valid_21626210 != nil:
    section.add "Version", valid_21626210
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626211: Call_GetUpdateJob_21626195; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_21626211.validator(path, query, header, formData, body, _)
  let scheme = call_21626211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626211.makeUrl(scheme.get, call_21626211.host, call_21626211.base,
                               call_21626211.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626211, uri, valid, _)

proc call*(call_21626212: Call_GetUpdateJob_21626195; SignatureMethod: string;
          Manifest: string; JobId: string; Signature: string; ValidateOnly: bool;
          Timestamp: string; SignatureVersion: string; AWSAccessKeyId: string;
          APIVersion: string = ""; Action: string = "UpdateJob";
          JobType: string = "Import"; Operation: string = "UpdateJob";
          Version: string = "2010-06-01"): Recallable =
  ## getUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   SignatureMethod: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Signature: string (required)
  ##   Action: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: string (required)
  ##   Operation: string (required)
  ##   SignatureVersion: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   Version: string (required)
  var query_21626213 = newJObject()
  add(query_21626213, "SignatureMethod", newJString(SignatureMethod))
  add(query_21626213, "Manifest", newJString(Manifest))
  add(query_21626213, "JobId", newJString(JobId))
  add(query_21626213, "APIVersion", newJString(APIVersion))
  add(query_21626213, "Signature", newJString(Signature))
  add(query_21626213, "Action", newJString(Action))
  add(query_21626213, "JobType", newJString(JobType))
  add(query_21626213, "ValidateOnly", newJBool(ValidateOnly))
  add(query_21626213, "Timestamp", newJString(Timestamp))
  add(query_21626213, "Operation", newJString(Operation))
  add(query_21626213, "SignatureVersion", newJString(SignatureVersion))
  add(query_21626213, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_21626213, "Version", newJString(Version))
  result = call_21626212.call(nil, query_21626213, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_21626195(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_21626196, base: "/", makeUrl: url_GetUpdateJob_21626197,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}