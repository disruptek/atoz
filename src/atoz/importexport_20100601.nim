
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCancelJob_599960 = ref object of OpenApiRestCall_599352
proc url_PostCancelJob_599962(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCancelJob_599961(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599963 = query.getOrDefault("SignatureMethod")
  valid_599963 = validateParameter(valid_599963, JString, required = true,
                                 default = nil)
  if valid_599963 != nil:
    section.add "SignatureMethod", valid_599963
  var valid_599964 = query.getOrDefault("Signature")
  valid_599964 = validateParameter(valid_599964, JString, required = true,
                                 default = nil)
  if valid_599964 != nil:
    section.add "Signature", valid_599964
  var valid_599965 = query.getOrDefault("Action")
  valid_599965 = validateParameter(valid_599965, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_599965 != nil:
    section.add "Action", valid_599965
  var valid_599966 = query.getOrDefault("Timestamp")
  valid_599966 = validateParameter(valid_599966, JString, required = true,
                                 default = nil)
  if valid_599966 != nil:
    section.add "Timestamp", valid_599966
  var valid_599967 = query.getOrDefault("Operation")
  valid_599967 = validateParameter(valid_599967, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_599967 != nil:
    section.add "Operation", valid_599967
  var valid_599968 = query.getOrDefault("SignatureVersion")
  valid_599968 = validateParameter(valid_599968, JString, required = true,
                                 default = nil)
  if valid_599968 != nil:
    section.add "SignatureVersion", valid_599968
  var valid_599969 = query.getOrDefault("AWSAccessKeyId")
  valid_599969 = validateParameter(valid_599969, JString, required = true,
                                 default = nil)
  if valid_599969 != nil:
    section.add "AWSAccessKeyId", valid_599969
  var valid_599970 = query.getOrDefault("Version")
  valid_599970 = validateParameter(valid_599970, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_599970 != nil:
    section.add "Version", valid_599970
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
  var valid_599971 = formData.getOrDefault("JobId")
  valid_599971 = validateParameter(valid_599971, JString, required = true,
                                 default = nil)
  if valid_599971 != nil:
    section.add "JobId", valid_599971
  var valid_599972 = formData.getOrDefault("APIVersion")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "APIVersion", valid_599972
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599973: Call_PostCancelJob_599960; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_599973.validator(path, query, header, formData, body)
  let scheme = call_599973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599973.url(scheme.get, call_599973.host, call_599973.base,
                         call_599973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599973, url, valid)

proc call*(call_599974: Call_PostCancelJob_599960; SignatureMethod: string;
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
  var query_599975 = newJObject()
  var formData_599976 = newJObject()
  add(query_599975, "SignatureMethod", newJString(SignatureMethod))
  add(query_599975, "Signature", newJString(Signature))
  add(query_599975, "Action", newJString(Action))
  add(query_599975, "Timestamp", newJString(Timestamp))
  add(formData_599976, "JobId", newJString(JobId))
  add(query_599975, "Operation", newJString(Operation))
  add(query_599975, "SignatureVersion", newJString(SignatureVersion))
  add(query_599975, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_599975, "Version", newJString(Version))
  add(formData_599976, "APIVersion", newJString(APIVersion))
  result = call_599974.call(nil, query_599975, nil, formData_599976, nil)

var postCancelJob* = Call_PostCancelJob_599960(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_599961, base: "/", url: url_PostCancelJob_599962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_599689 = ref object of OpenApiRestCall_599352
proc url_GetCancelJob_599691(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCancelJob_599690(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599803 = query.getOrDefault("SignatureMethod")
  valid_599803 = validateParameter(valid_599803, JString, required = true,
                                 default = nil)
  if valid_599803 != nil:
    section.add "SignatureMethod", valid_599803
  var valid_599804 = query.getOrDefault("JobId")
  valid_599804 = validateParameter(valid_599804, JString, required = true,
                                 default = nil)
  if valid_599804 != nil:
    section.add "JobId", valid_599804
  var valid_599805 = query.getOrDefault("APIVersion")
  valid_599805 = validateParameter(valid_599805, JString, required = false,
                                 default = nil)
  if valid_599805 != nil:
    section.add "APIVersion", valid_599805
  var valid_599806 = query.getOrDefault("Signature")
  valid_599806 = validateParameter(valid_599806, JString, required = true,
                                 default = nil)
  if valid_599806 != nil:
    section.add "Signature", valid_599806
  var valid_599820 = query.getOrDefault("Action")
  valid_599820 = validateParameter(valid_599820, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_599820 != nil:
    section.add "Action", valid_599820
  var valid_599821 = query.getOrDefault("Timestamp")
  valid_599821 = validateParameter(valid_599821, JString, required = true,
                                 default = nil)
  if valid_599821 != nil:
    section.add "Timestamp", valid_599821
  var valid_599822 = query.getOrDefault("Operation")
  valid_599822 = validateParameter(valid_599822, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_599822 != nil:
    section.add "Operation", valid_599822
  var valid_599823 = query.getOrDefault("SignatureVersion")
  valid_599823 = validateParameter(valid_599823, JString, required = true,
                                 default = nil)
  if valid_599823 != nil:
    section.add "SignatureVersion", valid_599823
  var valid_599824 = query.getOrDefault("AWSAccessKeyId")
  valid_599824 = validateParameter(valid_599824, JString, required = true,
                                 default = nil)
  if valid_599824 != nil:
    section.add "AWSAccessKeyId", valid_599824
  var valid_599825 = query.getOrDefault("Version")
  valid_599825 = validateParameter(valid_599825, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_599825 != nil:
    section.add "Version", valid_599825
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599848: Call_GetCancelJob_599689; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_599848.validator(path, query, header, formData, body)
  let scheme = call_599848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599848.url(scheme.get, call_599848.host, call_599848.base,
                         call_599848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599848, url, valid)

proc call*(call_599919: Call_GetCancelJob_599689; SignatureMethod: string;
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
  var query_599920 = newJObject()
  add(query_599920, "SignatureMethod", newJString(SignatureMethod))
  add(query_599920, "JobId", newJString(JobId))
  add(query_599920, "APIVersion", newJString(APIVersion))
  add(query_599920, "Signature", newJString(Signature))
  add(query_599920, "Action", newJString(Action))
  add(query_599920, "Timestamp", newJString(Timestamp))
  add(query_599920, "Operation", newJString(Operation))
  add(query_599920, "SignatureVersion", newJString(SignatureVersion))
  add(query_599920, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_599920, "Version", newJString(Version))
  result = call_599919.call(nil, query_599920, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_599689(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_599690, base: "/", url: url_GetCancelJob_599691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_599996 = ref object of OpenApiRestCall_599352
proc url_PostCreateJob_599998(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateJob_599997(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599999 = query.getOrDefault("SignatureMethod")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = nil)
  if valid_599999 != nil:
    section.add "SignatureMethod", valid_599999
  var valid_600000 = query.getOrDefault("Signature")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = nil)
  if valid_600000 != nil:
    section.add "Signature", valid_600000
  var valid_600001 = query.getOrDefault("Action")
  valid_600001 = validateParameter(valid_600001, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_600001 != nil:
    section.add "Action", valid_600001
  var valid_600002 = query.getOrDefault("Timestamp")
  valid_600002 = validateParameter(valid_600002, JString, required = true,
                                 default = nil)
  if valid_600002 != nil:
    section.add "Timestamp", valid_600002
  var valid_600003 = query.getOrDefault("Operation")
  valid_600003 = validateParameter(valid_600003, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_600003 != nil:
    section.add "Operation", valid_600003
  var valid_600004 = query.getOrDefault("SignatureVersion")
  valid_600004 = validateParameter(valid_600004, JString, required = true,
                                 default = nil)
  if valid_600004 != nil:
    section.add "SignatureVersion", valid_600004
  var valid_600005 = query.getOrDefault("AWSAccessKeyId")
  valid_600005 = validateParameter(valid_600005, JString, required = true,
                                 default = nil)
  if valid_600005 != nil:
    section.add "AWSAccessKeyId", valid_600005
  var valid_600006 = query.getOrDefault("Version")
  valid_600006 = validateParameter(valid_600006, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600006 != nil:
    section.add "Version", valid_600006
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
  var valid_600007 = formData.getOrDefault("ManifestAddendum")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "ManifestAddendum", valid_600007
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_600008 = formData.getOrDefault("Manifest")
  valid_600008 = validateParameter(valid_600008, JString, required = true,
                                 default = nil)
  if valid_600008 != nil:
    section.add "Manifest", valid_600008
  var valid_600009 = formData.getOrDefault("JobType")
  valid_600009 = validateParameter(valid_600009, JString, required = true,
                                 default = newJString("Import"))
  if valid_600009 != nil:
    section.add "JobType", valid_600009
  var valid_600010 = formData.getOrDefault("ValidateOnly")
  valid_600010 = validateParameter(valid_600010, JBool, required = true, default = nil)
  if valid_600010 != nil:
    section.add "ValidateOnly", valid_600010
  var valid_600011 = formData.getOrDefault("APIVersion")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "APIVersion", valid_600011
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600012: Call_PostCreateJob_599996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_600012.validator(path, query, header, formData, body)
  let scheme = call_600012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600012.url(scheme.get, call_600012.host, call_600012.base,
                         call_600012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600012, url, valid)

proc call*(call_600013: Call_PostCreateJob_599996; SignatureMethod: string;
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
  var query_600014 = newJObject()
  var formData_600015 = newJObject()
  add(query_600014, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600015, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_600014, "Signature", newJString(Signature))
  add(formData_600015, "Manifest", newJString(Manifest))
  add(formData_600015, "JobType", newJString(JobType))
  add(query_600014, "Action", newJString(Action))
  add(query_600014, "Timestamp", newJString(Timestamp))
  add(query_600014, "Operation", newJString(Operation))
  add(query_600014, "SignatureVersion", newJString(SignatureVersion))
  add(query_600014, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600014, "Version", newJString(Version))
  add(formData_600015, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_600015, "APIVersion", newJString(APIVersion))
  result = call_600013.call(nil, query_600014, nil, formData_600015, nil)

var postCreateJob* = Call_PostCreateJob_599996(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_599997, base: "/", url: url_PostCreateJob_599998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_599977 = ref object of OpenApiRestCall_599352
proc url_GetCreateJob_599979(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateJob_599978(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599980 = query.getOrDefault("SignatureMethod")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = nil)
  if valid_599980 != nil:
    section.add "SignatureMethod", valid_599980
  var valid_599981 = query.getOrDefault("Manifest")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = nil)
  if valid_599981 != nil:
    section.add "Manifest", valid_599981
  var valid_599982 = query.getOrDefault("APIVersion")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "APIVersion", valid_599982
  var valid_599983 = query.getOrDefault("Signature")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = nil)
  if valid_599983 != nil:
    section.add "Signature", valid_599983
  var valid_599984 = query.getOrDefault("Action")
  valid_599984 = validateParameter(valid_599984, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_599984 != nil:
    section.add "Action", valid_599984
  var valid_599985 = query.getOrDefault("JobType")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = newJString("Import"))
  if valid_599985 != nil:
    section.add "JobType", valid_599985
  var valid_599986 = query.getOrDefault("ValidateOnly")
  valid_599986 = validateParameter(valid_599986, JBool, required = true, default = nil)
  if valid_599986 != nil:
    section.add "ValidateOnly", valid_599986
  var valid_599987 = query.getOrDefault("Timestamp")
  valid_599987 = validateParameter(valid_599987, JString, required = true,
                                 default = nil)
  if valid_599987 != nil:
    section.add "Timestamp", valid_599987
  var valid_599988 = query.getOrDefault("ManifestAddendum")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "ManifestAddendum", valid_599988
  var valid_599989 = query.getOrDefault("Operation")
  valid_599989 = validateParameter(valid_599989, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_599989 != nil:
    section.add "Operation", valid_599989
  var valid_599990 = query.getOrDefault("SignatureVersion")
  valid_599990 = validateParameter(valid_599990, JString, required = true,
                                 default = nil)
  if valid_599990 != nil:
    section.add "SignatureVersion", valid_599990
  var valid_599991 = query.getOrDefault("AWSAccessKeyId")
  valid_599991 = validateParameter(valid_599991, JString, required = true,
                                 default = nil)
  if valid_599991 != nil:
    section.add "AWSAccessKeyId", valid_599991
  var valid_599992 = query.getOrDefault("Version")
  valid_599992 = validateParameter(valid_599992, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_599992 != nil:
    section.add "Version", valid_599992
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599993: Call_GetCreateJob_599977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_599993.validator(path, query, header, formData, body)
  let scheme = call_599993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599993.url(scheme.get, call_599993.host, call_599993.base,
                         call_599993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599993, url, valid)

proc call*(call_599994: Call_GetCreateJob_599977; SignatureMethod: string;
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
  var query_599995 = newJObject()
  add(query_599995, "SignatureMethod", newJString(SignatureMethod))
  add(query_599995, "Manifest", newJString(Manifest))
  add(query_599995, "APIVersion", newJString(APIVersion))
  add(query_599995, "Signature", newJString(Signature))
  add(query_599995, "Action", newJString(Action))
  add(query_599995, "JobType", newJString(JobType))
  add(query_599995, "ValidateOnly", newJBool(ValidateOnly))
  add(query_599995, "Timestamp", newJString(Timestamp))
  add(query_599995, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_599995, "Operation", newJString(Operation))
  add(query_599995, "SignatureVersion", newJString(SignatureVersion))
  add(query_599995, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_599995, "Version", newJString(Version))
  result = call_599994.call(nil, query_599995, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_599977(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_599978, base: "/", url: url_GetCreateJob_599979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_600042 = ref object of OpenApiRestCall_599352
proc url_PostGetShippingLabel_600044(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetShippingLabel_600043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600045 = query.getOrDefault("SignatureMethod")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = nil)
  if valid_600045 != nil:
    section.add "SignatureMethod", valid_600045
  var valid_600046 = query.getOrDefault("Signature")
  valid_600046 = validateParameter(valid_600046, JString, required = true,
                                 default = nil)
  if valid_600046 != nil:
    section.add "Signature", valid_600046
  var valid_600047 = query.getOrDefault("Action")
  valid_600047 = validateParameter(valid_600047, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_600047 != nil:
    section.add "Action", valid_600047
  var valid_600048 = query.getOrDefault("Timestamp")
  valid_600048 = validateParameter(valid_600048, JString, required = true,
                                 default = nil)
  if valid_600048 != nil:
    section.add "Timestamp", valid_600048
  var valid_600049 = query.getOrDefault("Operation")
  valid_600049 = validateParameter(valid_600049, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_600049 != nil:
    section.add "Operation", valid_600049
  var valid_600050 = query.getOrDefault("SignatureVersion")
  valid_600050 = validateParameter(valid_600050, JString, required = true,
                                 default = nil)
  if valid_600050 != nil:
    section.add "SignatureVersion", valid_600050
  var valid_600051 = query.getOrDefault("AWSAccessKeyId")
  valid_600051 = validateParameter(valid_600051, JString, required = true,
                                 default = nil)
  if valid_600051 != nil:
    section.add "AWSAccessKeyId", valid_600051
  var valid_600052 = query.getOrDefault("Version")
  valid_600052 = validateParameter(valid_600052, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600052 != nil:
    section.add "Version", valid_600052
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
  var valid_600053 = formData.getOrDefault("company")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "company", valid_600053
  var valid_600054 = formData.getOrDefault("stateOrProvince")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "stateOrProvince", valid_600054
  var valid_600055 = formData.getOrDefault("street1")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "street1", valid_600055
  var valid_600056 = formData.getOrDefault("name")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "name", valid_600056
  var valid_600057 = formData.getOrDefault("street3")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "street3", valid_600057
  var valid_600058 = formData.getOrDefault("city")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "city", valid_600058
  var valid_600059 = formData.getOrDefault("postalCode")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "postalCode", valid_600059
  var valid_600060 = formData.getOrDefault("phoneNumber")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "phoneNumber", valid_600060
  var valid_600061 = formData.getOrDefault("street2")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "street2", valid_600061
  var valid_600062 = formData.getOrDefault("country")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "country", valid_600062
  var valid_600063 = formData.getOrDefault("APIVersion")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "APIVersion", valid_600063
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_600064 = formData.getOrDefault("jobIds")
  valid_600064 = validateParameter(valid_600064, JArray, required = true, default = nil)
  if valid_600064 != nil:
    section.add "jobIds", valid_600064
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600065: Call_PostGetShippingLabel_600042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_600065.validator(path, query, header, formData, body)
  let scheme = call_600065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600065.url(scheme.get, call_600065.host, call_600065.base,
                         call_600065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600065, url, valid)

proc call*(call_600066: Call_PostGetShippingLabel_600042; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          AWSAccessKeyId: string; jobIds: JsonNode; company: string = "";
          stateOrProvince: string = ""; street1: string = ""; name: string = "";
          street3: string = ""; Action: string = "GetShippingLabel"; city: string = "";
          postalCode: string = ""; Operation: string = "GetShippingLabel";
          phoneNumber: string = ""; street2: string = "";
          Version: string = "2010-06-01"; country: string = ""; APIVersion: string = ""): Recallable =
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
  var query_600067 = newJObject()
  var formData_600068 = newJObject()
  add(formData_600068, "company", newJString(company))
  add(query_600067, "SignatureMethod", newJString(SignatureMethod))
  add(formData_600068, "stateOrProvince", newJString(stateOrProvince))
  add(query_600067, "Signature", newJString(Signature))
  add(formData_600068, "street1", newJString(street1))
  add(formData_600068, "name", newJString(name))
  add(formData_600068, "street3", newJString(street3))
  add(query_600067, "Action", newJString(Action))
  add(formData_600068, "city", newJString(city))
  add(query_600067, "Timestamp", newJString(Timestamp))
  add(formData_600068, "postalCode", newJString(postalCode))
  add(query_600067, "Operation", newJString(Operation))
  add(query_600067, "SignatureVersion", newJString(SignatureVersion))
  add(formData_600068, "phoneNumber", newJString(phoneNumber))
  add(query_600067, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_600068, "street2", newJString(street2))
  add(query_600067, "Version", newJString(Version))
  add(formData_600068, "country", newJString(country))
  add(formData_600068, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_600068.add "jobIds", jobIds
  result = call_600066.call(nil, query_600067, nil, formData_600068, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_600042(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_600043, base: "/",
    url: url_PostGetShippingLabel_600044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_600016 = ref object of OpenApiRestCall_599352
proc url_GetGetShippingLabel_600018(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetShippingLabel_600017(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600019 = query.getOrDefault("SignatureMethod")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = nil)
  if valid_600019 != nil:
    section.add "SignatureMethod", valid_600019
  var valid_600020 = query.getOrDefault("city")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "city", valid_600020
  var valid_600021 = query.getOrDefault("country")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "country", valid_600021
  var valid_600022 = query.getOrDefault("stateOrProvince")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "stateOrProvince", valid_600022
  var valid_600023 = query.getOrDefault("company")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "company", valid_600023
  var valid_600024 = query.getOrDefault("APIVersion")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "APIVersion", valid_600024
  var valid_600025 = query.getOrDefault("phoneNumber")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "phoneNumber", valid_600025
  var valid_600026 = query.getOrDefault("street1")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "street1", valid_600026
  var valid_600027 = query.getOrDefault("Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = true,
                                 default = nil)
  if valid_600027 != nil:
    section.add "Signature", valid_600027
  var valid_600028 = query.getOrDefault("street3")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "street3", valid_600028
  var valid_600029 = query.getOrDefault("Action")
  valid_600029 = validateParameter(valid_600029, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_600029 != nil:
    section.add "Action", valid_600029
  var valid_600030 = query.getOrDefault("name")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "name", valid_600030
  var valid_600031 = query.getOrDefault("Timestamp")
  valid_600031 = validateParameter(valid_600031, JString, required = true,
                                 default = nil)
  if valid_600031 != nil:
    section.add "Timestamp", valid_600031
  var valid_600032 = query.getOrDefault("Operation")
  valid_600032 = validateParameter(valid_600032, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_600032 != nil:
    section.add "Operation", valid_600032
  var valid_600033 = query.getOrDefault("SignatureVersion")
  valid_600033 = validateParameter(valid_600033, JString, required = true,
                                 default = nil)
  if valid_600033 != nil:
    section.add "SignatureVersion", valid_600033
  var valid_600034 = query.getOrDefault("jobIds")
  valid_600034 = validateParameter(valid_600034, JArray, required = true, default = nil)
  if valid_600034 != nil:
    section.add "jobIds", valid_600034
  var valid_600035 = query.getOrDefault("AWSAccessKeyId")
  valid_600035 = validateParameter(valid_600035, JString, required = true,
                                 default = nil)
  if valid_600035 != nil:
    section.add "AWSAccessKeyId", valid_600035
  var valid_600036 = query.getOrDefault("street2")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "street2", valid_600036
  var valid_600037 = query.getOrDefault("postalCode")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "postalCode", valid_600037
  var valid_600038 = query.getOrDefault("Version")
  valid_600038 = validateParameter(valid_600038, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600038 != nil:
    section.add "Version", valid_600038
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600039: Call_GetGetShippingLabel_600016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_600039.validator(path, query, header, formData, body)
  let scheme = call_600039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600039.url(scheme.get, call_600039.host, call_600039.base,
                         call_600039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600039, url, valid)

proc call*(call_600040: Call_GetGetShippingLabel_600016; SignatureMethod: string;
          Signature: string; Timestamp: string; SignatureVersion: string;
          jobIds: JsonNode; AWSAccessKeyId: string; city: string = "";
          country: string = ""; stateOrProvince: string = ""; company: string = "";
          APIVersion: string = ""; phoneNumber: string = ""; street1: string = "";
          street3: string = ""; Action: string = "GetShippingLabel"; name: string = "";
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
  var query_600041 = newJObject()
  add(query_600041, "SignatureMethod", newJString(SignatureMethod))
  add(query_600041, "city", newJString(city))
  add(query_600041, "country", newJString(country))
  add(query_600041, "stateOrProvince", newJString(stateOrProvince))
  add(query_600041, "company", newJString(company))
  add(query_600041, "APIVersion", newJString(APIVersion))
  add(query_600041, "phoneNumber", newJString(phoneNumber))
  add(query_600041, "street1", newJString(street1))
  add(query_600041, "Signature", newJString(Signature))
  add(query_600041, "street3", newJString(street3))
  add(query_600041, "Action", newJString(Action))
  add(query_600041, "name", newJString(name))
  add(query_600041, "Timestamp", newJString(Timestamp))
  add(query_600041, "Operation", newJString(Operation))
  add(query_600041, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_600041.add "jobIds", jobIds
  add(query_600041, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600041, "street2", newJString(street2))
  add(query_600041, "postalCode", newJString(postalCode))
  add(query_600041, "Version", newJString(Version))
  result = call_600040.call(nil, query_600041, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_600016(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_600017, base: "/",
    url: url_GetGetShippingLabel_600018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_600085 = ref object of OpenApiRestCall_599352
proc url_PostGetStatus_600087(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetStatus_600086(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600088 = query.getOrDefault("SignatureMethod")
  valid_600088 = validateParameter(valid_600088, JString, required = true,
                                 default = nil)
  if valid_600088 != nil:
    section.add "SignatureMethod", valid_600088
  var valid_600089 = query.getOrDefault("Signature")
  valid_600089 = validateParameter(valid_600089, JString, required = true,
                                 default = nil)
  if valid_600089 != nil:
    section.add "Signature", valid_600089
  var valid_600090 = query.getOrDefault("Action")
  valid_600090 = validateParameter(valid_600090, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_600090 != nil:
    section.add "Action", valid_600090
  var valid_600091 = query.getOrDefault("Timestamp")
  valid_600091 = validateParameter(valid_600091, JString, required = true,
                                 default = nil)
  if valid_600091 != nil:
    section.add "Timestamp", valid_600091
  var valid_600092 = query.getOrDefault("Operation")
  valid_600092 = validateParameter(valid_600092, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_600092 != nil:
    section.add "Operation", valid_600092
  var valid_600093 = query.getOrDefault("SignatureVersion")
  valid_600093 = validateParameter(valid_600093, JString, required = true,
                                 default = nil)
  if valid_600093 != nil:
    section.add "SignatureVersion", valid_600093
  var valid_600094 = query.getOrDefault("AWSAccessKeyId")
  valid_600094 = validateParameter(valid_600094, JString, required = true,
                                 default = nil)
  if valid_600094 != nil:
    section.add "AWSAccessKeyId", valid_600094
  var valid_600095 = query.getOrDefault("Version")
  valid_600095 = validateParameter(valid_600095, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600095 != nil:
    section.add "Version", valid_600095
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
  var valid_600096 = formData.getOrDefault("JobId")
  valid_600096 = validateParameter(valid_600096, JString, required = true,
                                 default = nil)
  if valid_600096 != nil:
    section.add "JobId", valid_600096
  var valid_600097 = formData.getOrDefault("APIVersion")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "APIVersion", valid_600097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600098: Call_PostGetStatus_600085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_600098.validator(path, query, header, formData, body)
  let scheme = call_600098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600098.url(scheme.get, call_600098.host, call_600098.base,
                         call_600098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600098, url, valid)

proc call*(call_600099: Call_PostGetStatus_600085; SignatureMethod: string;
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
  var query_600100 = newJObject()
  var formData_600101 = newJObject()
  add(query_600100, "SignatureMethod", newJString(SignatureMethod))
  add(query_600100, "Signature", newJString(Signature))
  add(query_600100, "Action", newJString(Action))
  add(query_600100, "Timestamp", newJString(Timestamp))
  add(formData_600101, "JobId", newJString(JobId))
  add(query_600100, "Operation", newJString(Operation))
  add(query_600100, "SignatureVersion", newJString(SignatureVersion))
  add(query_600100, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600100, "Version", newJString(Version))
  add(formData_600101, "APIVersion", newJString(APIVersion))
  result = call_600099.call(nil, query_600100, nil, formData_600101, nil)

var postGetStatus* = Call_PostGetStatus_600085(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_600086, base: "/", url: url_PostGetStatus_600087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_600069 = ref object of OpenApiRestCall_599352
proc url_GetGetStatus_600071(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetStatus_600070(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600072 = query.getOrDefault("SignatureMethod")
  valid_600072 = validateParameter(valid_600072, JString, required = true,
                                 default = nil)
  if valid_600072 != nil:
    section.add "SignatureMethod", valid_600072
  var valid_600073 = query.getOrDefault("JobId")
  valid_600073 = validateParameter(valid_600073, JString, required = true,
                                 default = nil)
  if valid_600073 != nil:
    section.add "JobId", valid_600073
  var valid_600074 = query.getOrDefault("APIVersion")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "APIVersion", valid_600074
  var valid_600075 = query.getOrDefault("Signature")
  valid_600075 = validateParameter(valid_600075, JString, required = true,
                                 default = nil)
  if valid_600075 != nil:
    section.add "Signature", valid_600075
  var valid_600076 = query.getOrDefault("Action")
  valid_600076 = validateParameter(valid_600076, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_600076 != nil:
    section.add "Action", valid_600076
  var valid_600077 = query.getOrDefault("Timestamp")
  valid_600077 = validateParameter(valid_600077, JString, required = true,
                                 default = nil)
  if valid_600077 != nil:
    section.add "Timestamp", valid_600077
  var valid_600078 = query.getOrDefault("Operation")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_600078 != nil:
    section.add "Operation", valid_600078
  var valid_600079 = query.getOrDefault("SignatureVersion")
  valid_600079 = validateParameter(valid_600079, JString, required = true,
                                 default = nil)
  if valid_600079 != nil:
    section.add "SignatureVersion", valid_600079
  var valid_600080 = query.getOrDefault("AWSAccessKeyId")
  valid_600080 = validateParameter(valid_600080, JString, required = true,
                                 default = nil)
  if valid_600080 != nil:
    section.add "AWSAccessKeyId", valid_600080
  var valid_600081 = query.getOrDefault("Version")
  valid_600081 = validateParameter(valid_600081, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600081 != nil:
    section.add "Version", valid_600081
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600082: Call_GetGetStatus_600069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_600082.validator(path, query, header, formData, body)
  let scheme = call_600082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600082.url(scheme.get, call_600082.host, call_600082.base,
                         call_600082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600082, url, valid)

proc call*(call_600083: Call_GetGetStatus_600069; SignatureMethod: string;
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
  var query_600084 = newJObject()
  add(query_600084, "SignatureMethod", newJString(SignatureMethod))
  add(query_600084, "JobId", newJString(JobId))
  add(query_600084, "APIVersion", newJString(APIVersion))
  add(query_600084, "Signature", newJString(Signature))
  add(query_600084, "Action", newJString(Action))
  add(query_600084, "Timestamp", newJString(Timestamp))
  add(query_600084, "Operation", newJString(Operation))
  add(query_600084, "SignatureVersion", newJString(SignatureVersion))
  add(query_600084, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600084, "Version", newJString(Version))
  result = call_600083.call(nil, query_600084, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_600069(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_600070, base: "/", url: url_GetGetStatus_600071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_600119 = ref object of OpenApiRestCall_599352
proc url_PostListJobs_600121(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListJobs_600120(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600122 = query.getOrDefault("SignatureMethod")
  valid_600122 = validateParameter(valid_600122, JString, required = true,
                                 default = nil)
  if valid_600122 != nil:
    section.add "SignatureMethod", valid_600122
  var valid_600123 = query.getOrDefault("Signature")
  valid_600123 = validateParameter(valid_600123, JString, required = true,
                                 default = nil)
  if valid_600123 != nil:
    section.add "Signature", valid_600123
  var valid_600124 = query.getOrDefault("Action")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_600124 != nil:
    section.add "Action", valid_600124
  var valid_600125 = query.getOrDefault("Timestamp")
  valid_600125 = validateParameter(valid_600125, JString, required = true,
                                 default = nil)
  if valid_600125 != nil:
    section.add "Timestamp", valid_600125
  var valid_600126 = query.getOrDefault("Operation")
  valid_600126 = validateParameter(valid_600126, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_600126 != nil:
    section.add "Operation", valid_600126
  var valid_600127 = query.getOrDefault("SignatureVersion")
  valid_600127 = validateParameter(valid_600127, JString, required = true,
                                 default = nil)
  if valid_600127 != nil:
    section.add "SignatureVersion", valid_600127
  var valid_600128 = query.getOrDefault("AWSAccessKeyId")
  valid_600128 = validateParameter(valid_600128, JString, required = true,
                                 default = nil)
  if valid_600128 != nil:
    section.add "AWSAccessKeyId", valid_600128
  var valid_600129 = query.getOrDefault("Version")
  valid_600129 = validateParameter(valid_600129, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600129 != nil:
    section.add "Version", valid_600129
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
  var valid_600130 = formData.getOrDefault("Marker")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "Marker", valid_600130
  var valid_600131 = formData.getOrDefault("MaxJobs")
  valid_600131 = validateParameter(valid_600131, JInt, required = false, default = nil)
  if valid_600131 != nil:
    section.add "MaxJobs", valid_600131
  var valid_600132 = formData.getOrDefault("APIVersion")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "APIVersion", valid_600132
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600133: Call_PostListJobs_600119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_600133.validator(path, query, header, formData, body)
  let scheme = call_600133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600133.url(scheme.get, call_600133.host, call_600133.base,
                         call_600133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600133, url, valid)

proc call*(call_600134: Call_PostListJobs_600119; SignatureMethod: string;
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
  var query_600135 = newJObject()
  var formData_600136 = newJObject()
  add(query_600135, "SignatureMethod", newJString(SignatureMethod))
  add(query_600135, "Signature", newJString(Signature))
  add(formData_600136, "Marker", newJString(Marker))
  add(query_600135, "Action", newJString(Action))
  add(formData_600136, "MaxJobs", newJInt(MaxJobs))
  add(query_600135, "Timestamp", newJString(Timestamp))
  add(query_600135, "Operation", newJString(Operation))
  add(query_600135, "SignatureVersion", newJString(SignatureVersion))
  add(query_600135, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600135, "Version", newJString(Version))
  add(formData_600136, "APIVersion", newJString(APIVersion))
  result = call_600134.call(nil, query_600135, nil, formData_600136, nil)

var postListJobs* = Call_PostListJobs_600119(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_600120, base: "/", url: url_PostListJobs_600121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_600102 = ref object of OpenApiRestCall_599352
proc url_GetListJobs_600104(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListJobs_600103(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600105 = query.getOrDefault("SignatureMethod")
  valid_600105 = validateParameter(valid_600105, JString, required = true,
                                 default = nil)
  if valid_600105 != nil:
    section.add "SignatureMethod", valid_600105
  var valid_600106 = query.getOrDefault("APIVersion")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "APIVersion", valid_600106
  var valid_600107 = query.getOrDefault("Signature")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "Signature", valid_600107
  var valid_600108 = query.getOrDefault("MaxJobs")
  valid_600108 = validateParameter(valid_600108, JInt, required = false, default = nil)
  if valid_600108 != nil:
    section.add "MaxJobs", valid_600108
  var valid_600109 = query.getOrDefault("Action")
  valid_600109 = validateParameter(valid_600109, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_600109 != nil:
    section.add "Action", valid_600109
  var valid_600110 = query.getOrDefault("Marker")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "Marker", valid_600110
  var valid_600111 = query.getOrDefault("Timestamp")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = nil)
  if valid_600111 != nil:
    section.add "Timestamp", valid_600111
  var valid_600112 = query.getOrDefault("Operation")
  valid_600112 = validateParameter(valid_600112, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_600112 != nil:
    section.add "Operation", valid_600112
  var valid_600113 = query.getOrDefault("SignatureVersion")
  valid_600113 = validateParameter(valid_600113, JString, required = true,
                                 default = nil)
  if valid_600113 != nil:
    section.add "SignatureVersion", valid_600113
  var valid_600114 = query.getOrDefault("AWSAccessKeyId")
  valid_600114 = validateParameter(valid_600114, JString, required = true,
                                 default = nil)
  if valid_600114 != nil:
    section.add "AWSAccessKeyId", valid_600114
  var valid_600115 = query.getOrDefault("Version")
  valid_600115 = validateParameter(valid_600115, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600115 != nil:
    section.add "Version", valid_600115
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600116: Call_GetListJobs_600102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_600116.validator(path, query, header, formData, body)
  let scheme = call_600116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600116.url(scheme.get, call_600116.host, call_600116.base,
                         call_600116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600116, url, valid)

proc call*(call_600117: Call_GetListJobs_600102; SignatureMethod: string;
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
  var query_600118 = newJObject()
  add(query_600118, "SignatureMethod", newJString(SignatureMethod))
  add(query_600118, "APIVersion", newJString(APIVersion))
  add(query_600118, "Signature", newJString(Signature))
  add(query_600118, "MaxJobs", newJInt(MaxJobs))
  add(query_600118, "Action", newJString(Action))
  add(query_600118, "Marker", newJString(Marker))
  add(query_600118, "Timestamp", newJString(Timestamp))
  add(query_600118, "Operation", newJString(Operation))
  add(query_600118, "SignatureVersion", newJString(SignatureVersion))
  add(query_600118, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600118, "Version", newJString(Version))
  result = call_600117.call(nil, query_600118, nil, nil, nil)

var getListJobs* = Call_GetListJobs_600102(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_600103,
                                        base: "/", url: url_GetListJobs_600104,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_600156 = ref object of OpenApiRestCall_599352
proc url_PostUpdateJob_600158(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateJob_600157(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600159 = query.getOrDefault("SignatureMethod")
  valid_600159 = validateParameter(valid_600159, JString, required = true,
                                 default = nil)
  if valid_600159 != nil:
    section.add "SignatureMethod", valid_600159
  var valid_600160 = query.getOrDefault("Signature")
  valid_600160 = validateParameter(valid_600160, JString, required = true,
                                 default = nil)
  if valid_600160 != nil:
    section.add "Signature", valid_600160
  var valid_600161 = query.getOrDefault("Action")
  valid_600161 = validateParameter(valid_600161, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_600161 != nil:
    section.add "Action", valid_600161
  var valid_600162 = query.getOrDefault("Timestamp")
  valid_600162 = validateParameter(valid_600162, JString, required = true,
                                 default = nil)
  if valid_600162 != nil:
    section.add "Timestamp", valid_600162
  var valid_600163 = query.getOrDefault("Operation")
  valid_600163 = validateParameter(valid_600163, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_600163 != nil:
    section.add "Operation", valid_600163
  var valid_600164 = query.getOrDefault("SignatureVersion")
  valid_600164 = validateParameter(valid_600164, JString, required = true,
                                 default = nil)
  if valid_600164 != nil:
    section.add "SignatureVersion", valid_600164
  var valid_600165 = query.getOrDefault("AWSAccessKeyId")
  valid_600165 = validateParameter(valid_600165, JString, required = true,
                                 default = nil)
  if valid_600165 != nil:
    section.add "AWSAccessKeyId", valid_600165
  var valid_600166 = query.getOrDefault("Version")
  valid_600166 = validateParameter(valid_600166, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600166 != nil:
    section.add "Version", valid_600166
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
  var valid_600167 = formData.getOrDefault("Manifest")
  valid_600167 = validateParameter(valid_600167, JString, required = true,
                                 default = nil)
  if valid_600167 != nil:
    section.add "Manifest", valid_600167
  var valid_600168 = formData.getOrDefault("JobType")
  valid_600168 = validateParameter(valid_600168, JString, required = true,
                                 default = newJString("Import"))
  if valid_600168 != nil:
    section.add "JobType", valid_600168
  var valid_600169 = formData.getOrDefault("JobId")
  valid_600169 = validateParameter(valid_600169, JString, required = true,
                                 default = nil)
  if valid_600169 != nil:
    section.add "JobId", valid_600169
  var valid_600170 = formData.getOrDefault("ValidateOnly")
  valid_600170 = validateParameter(valid_600170, JBool, required = true, default = nil)
  if valid_600170 != nil:
    section.add "ValidateOnly", valid_600170
  var valid_600171 = formData.getOrDefault("APIVersion")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "APIVersion", valid_600171
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600172: Call_PostUpdateJob_600156; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_600172.validator(path, query, header, formData, body)
  let scheme = call_600172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600172.url(scheme.get, call_600172.host, call_600172.base,
                         call_600172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600172, url, valid)

proc call*(call_600173: Call_PostUpdateJob_600156; SignatureMethod: string;
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
  var query_600174 = newJObject()
  var formData_600175 = newJObject()
  add(query_600174, "SignatureMethod", newJString(SignatureMethod))
  add(query_600174, "Signature", newJString(Signature))
  add(formData_600175, "Manifest", newJString(Manifest))
  add(formData_600175, "JobType", newJString(JobType))
  add(query_600174, "Action", newJString(Action))
  add(query_600174, "Timestamp", newJString(Timestamp))
  add(formData_600175, "JobId", newJString(JobId))
  add(query_600174, "Operation", newJString(Operation))
  add(query_600174, "SignatureVersion", newJString(SignatureVersion))
  add(query_600174, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600174, "Version", newJString(Version))
  add(formData_600175, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_600175, "APIVersion", newJString(APIVersion))
  result = call_600173.call(nil, query_600174, nil, formData_600175, nil)

var postUpdateJob* = Call_PostUpdateJob_600156(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_600157, base: "/", url: url_PostUpdateJob_600158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_600137 = ref object of OpenApiRestCall_599352
proc url_GetUpdateJob_600139(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateJob_600138(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600140 = query.getOrDefault("SignatureMethod")
  valid_600140 = validateParameter(valid_600140, JString, required = true,
                                 default = nil)
  if valid_600140 != nil:
    section.add "SignatureMethod", valid_600140
  var valid_600141 = query.getOrDefault("Manifest")
  valid_600141 = validateParameter(valid_600141, JString, required = true,
                                 default = nil)
  if valid_600141 != nil:
    section.add "Manifest", valid_600141
  var valid_600142 = query.getOrDefault("JobId")
  valid_600142 = validateParameter(valid_600142, JString, required = true,
                                 default = nil)
  if valid_600142 != nil:
    section.add "JobId", valid_600142
  var valid_600143 = query.getOrDefault("APIVersion")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "APIVersion", valid_600143
  var valid_600144 = query.getOrDefault("Signature")
  valid_600144 = validateParameter(valid_600144, JString, required = true,
                                 default = nil)
  if valid_600144 != nil:
    section.add "Signature", valid_600144
  var valid_600145 = query.getOrDefault("Action")
  valid_600145 = validateParameter(valid_600145, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_600145 != nil:
    section.add "Action", valid_600145
  var valid_600146 = query.getOrDefault("JobType")
  valid_600146 = validateParameter(valid_600146, JString, required = true,
                                 default = newJString("Import"))
  if valid_600146 != nil:
    section.add "JobType", valid_600146
  var valid_600147 = query.getOrDefault("ValidateOnly")
  valid_600147 = validateParameter(valid_600147, JBool, required = true, default = nil)
  if valid_600147 != nil:
    section.add "ValidateOnly", valid_600147
  var valid_600148 = query.getOrDefault("Timestamp")
  valid_600148 = validateParameter(valid_600148, JString, required = true,
                                 default = nil)
  if valid_600148 != nil:
    section.add "Timestamp", valid_600148
  var valid_600149 = query.getOrDefault("Operation")
  valid_600149 = validateParameter(valid_600149, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_600149 != nil:
    section.add "Operation", valid_600149
  var valid_600150 = query.getOrDefault("SignatureVersion")
  valid_600150 = validateParameter(valid_600150, JString, required = true,
                                 default = nil)
  if valid_600150 != nil:
    section.add "SignatureVersion", valid_600150
  var valid_600151 = query.getOrDefault("AWSAccessKeyId")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = nil)
  if valid_600151 != nil:
    section.add "AWSAccessKeyId", valid_600151
  var valid_600152 = query.getOrDefault("Version")
  valid_600152 = validateParameter(valid_600152, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_600152 != nil:
    section.add "Version", valid_600152
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600153: Call_GetUpdateJob_600137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_600153.validator(path, query, header, formData, body)
  let scheme = call_600153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600153.url(scheme.get, call_600153.host, call_600153.base,
                         call_600153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600153, url, valid)

proc call*(call_600154: Call_GetUpdateJob_600137; SignatureMethod: string;
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
  var query_600155 = newJObject()
  add(query_600155, "SignatureMethod", newJString(SignatureMethod))
  add(query_600155, "Manifest", newJString(Manifest))
  add(query_600155, "JobId", newJString(JobId))
  add(query_600155, "APIVersion", newJString(APIVersion))
  add(query_600155, "Signature", newJString(Signature))
  add(query_600155, "Action", newJString(Action))
  add(query_600155, "JobType", newJString(JobType))
  add(query_600155, "ValidateOnly", newJBool(ValidateOnly))
  add(query_600155, "Timestamp", newJString(Timestamp))
  add(query_600155, "Operation", newJString(Operation))
  add(query_600155, "SignatureVersion", newJString(SignatureVersion))
  add(query_600155, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_600155, "Version", newJString(Version))
  result = call_600154.call(nil, query_600155, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_600137(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_600138, base: "/", url: url_GetUpdateJob_600139,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let
    algo = SHA256
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
