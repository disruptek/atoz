
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

  OpenApiRestCall_610642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610642): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCancelJob_611251 = ref object of OpenApiRestCall_610642
proc url_PostCancelJob_611253(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCancelJob_611252(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611254 = query.getOrDefault("Signature")
  valid_611254 = validateParameter(valid_611254, JString, required = true,
                                 default = nil)
  if valid_611254 != nil:
    section.add "Signature", valid_611254
  var valid_611255 = query.getOrDefault("AWSAccessKeyId")
  valid_611255 = validateParameter(valid_611255, JString, required = true,
                                 default = nil)
  if valid_611255 != nil:
    section.add "AWSAccessKeyId", valid_611255
  var valid_611256 = query.getOrDefault("SignatureMethod")
  valid_611256 = validateParameter(valid_611256, JString, required = true,
                                 default = nil)
  if valid_611256 != nil:
    section.add "SignatureMethod", valid_611256
  var valid_611257 = query.getOrDefault("Timestamp")
  valid_611257 = validateParameter(valid_611257, JString, required = true,
                                 default = nil)
  if valid_611257 != nil:
    section.add "Timestamp", valid_611257
  var valid_611258 = query.getOrDefault("Action")
  valid_611258 = validateParameter(valid_611258, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_611258 != nil:
    section.add "Action", valid_611258
  var valid_611259 = query.getOrDefault("Operation")
  valid_611259 = validateParameter(valid_611259, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_611259 != nil:
    section.add "Operation", valid_611259
  var valid_611260 = query.getOrDefault("Version")
  valid_611260 = validateParameter(valid_611260, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611260 != nil:
    section.add "Version", valid_611260
  var valid_611261 = query.getOrDefault("SignatureVersion")
  valid_611261 = validateParameter(valid_611261, JString, required = true,
                                 default = nil)
  if valid_611261 != nil:
    section.add "SignatureVersion", valid_611261
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_611262 = formData.getOrDefault("APIVersion")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "APIVersion", valid_611262
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_611263 = formData.getOrDefault("JobId")
  valid_611263 = validateParameter(valid_611263, JString, required = true,
                                 default = nil)
  if valid_611263 != nil:
    section.add "JobId", valid_611263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611264: Call_PostCancelJob_611251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_611264.validator(path, query, header, formData, body)
  let scheme = call_611264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611264.url(scheme.get, call_611264.host, call_611264.base,
                         call_611264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611264, url, valid)

proc call*(call_611265: Call_PostCancelJob_611251; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          JobId: string; SignatureVersion: string; APIVersion: string = "";
          Action: string = "CancelJob"; Operation: string = "CancelJob";
          Version: string = "2010-06-01"): Recallable =
  ## postCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_611266 = newJObject()
  var formData_611267 = newJObject()
  add(query_611266, "Signature", newJString(Signature))
  add(query_611266, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611266, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611267, "APIVersion", newJString(APIVersion))
  add(query_611266, "Timestamp", newJString(Timestamp))
  add(query_611266, "Action", newJString(Action))
  add(query_611266, "Operation", newJString(Operation))
  add(formData_611267, "JobId", newJString(JobId))
  add(query_611266, "Version", newJString(Version))
  add(query_611266, "SignatureVersion", newJString(SignatureVersion))
  result = call_611265.call(nil, query_611266, nil, formData_611267, nil)

var postCancelJob* = Call_PostCancelJob_611251(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_611252, base: "/", url: url_PostCancelJob_611253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_610980 = ref object of OpenApiRestCall_610642
proc url_GetCancelJob_610982(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCancelJob_610981(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Version: JString (required)
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611094 = query.getOrDefault("Signature")
  valid_611094 = validateParameter(valid_611094, JString, required = true,
                                 default = nil)
  if valid_611094 != nil:
    section.add "Signature", valid_611094
  var valid_611095 = query.getOrDefault("AWSAccessKeyId")
  valid_611095 = validateParameter(valid_611095, JString, required = true,
                                 default = nil)
  if valid_611095 != nil:
    section.add "AWSAccessKeyId", valid_611095
  var valid_611096 = query.getOrDefault("SignatureMethod")
  valid_611096 = validateParameter(valid_611096, JString, required = true,
                                 default = nil)
  if valid_611096 != nil:
    section.add "SignatureMethod", valid_611096
  var valid_611097 = query.getOrDefault("Timestamp")
  valid_611097 = validateParameter(valid_611097, JString, required = true,
                                 default = nil)
  if valid_611097 != nil:
    section.add "Timestamp", valid_611097
  var valid_611111 = query.getOrDefault("Action")
  valid_611111 = validateParameter(valid_611111, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_611111 != nil:
    section.add "Action", valid_611111
  var valid_611112 = query.getOrDefault("Operation")
  valid_611112 = validateParameter(valid_611112, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_611112 != nil:
    section.add "Operation", valid_611112
  var valid_611113 = query.getOrDefault("APIVersion")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "APIVersion", valid_611113
  var valid_611114 = query.getOrDefault("Version")
  valid_611114 = validateParameter(valid_611114, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611114 != nil:
    section.add "Version", valid_611114
  var valid_611115 = query.getOrDefault("JobId")
  valid_611115 = validateParameter(valid_611115, JString, required = true,
                                 default = nil)
  if valid_611115 != nil:
    section.add "JobId", valid_611115
  var valid_611116 = query.getOrDefault("SignatureVersion")
  valid_611116 = validateParameter(valid_611116, JString, required = true,
                                 default = nil)
  if valid_611116 != nil:
    section.add "SignatureVersion", valid_611116
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611139: Call_GetCancelJob_610980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_611139.validator(path, query, header, formData, body)
  let scheme = call_611139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611139.url(scheme.get, call_611139.host, call_611139.base,
                         call_611139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611139, url, valid)

proc call*(call_611210: Call_GetCancelJob_610980; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          JobId: string; SignatureVersion: string; Action: string = "CancelJob";
          Operation: string = "CancelJob"; APIVersion: string = "";
          Version: string = "2010-06-01"): Recallable =
  ## getCancelJob
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Version: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   SignatureVersion: string (required)
  var query_611211 = newJObject()
  add(query_611211, "Signature", newJString(Signature))
  add(query_611211, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611211, "SignatureMethod", newJString(SignatureMethod))
  add(query_611211, "Timestamp", newJString(Timestamp))
  add(query_611211, "Action", newJString(Action))
  add(query_611211, "Operation", newJString(Operation))
  add(query_611211, "APIVersion", newJString(APIVersion))
  add(query_611211, "Version", newJString(Version))
  add(query_611211, "JobId", newJString(JobId))
  add(query_611211, "SignatureVersion", newJString(SignatureVersion))
  result = call_611210.call(nil, query_611211, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_610980(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_610981, base: "/", url: url_GetCancelJob_610982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_611287 = ref object of OpenApiRestCall_610642
proc url_PostCreateJob_611289(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateJob_611288(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611290 = query.getOrDefault("Signature")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "Signature", valid_611290
  var valid_611291 = query.getOrDefault("AWSAccessKeyId")
  valid_611291 = validateParameter(valid_611291, JString, required = true,
                                 default = nil)
  if valid_611291 != nil:
    section.add "AWSAccessKeyId", valid_611291
  var valid_611292 = query.getOrDefault("SignatureMethod")
  valid_611292 = validateParameter(valid_611292, JString, required = true,
                                 default = nil)
  if valid_611292 != nil:
    section.add "SignatureMethod", valid_611292
  var valid_611293 = query.getOrDefault("Timestamp")
  valid_611293 = validateParameter(valid_611293, JString, required = true,
                                 default = nil)
  if valid_611293 != nil:
    section.add "Timestamp", valid_611293
  var valid_611294 = query.getOrDefault("Action")
  valid_611294 = validateParameter(valid_611294, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_611294 != nil:
    section.add "Action", valid_611294
  var valid_611295 = query.getOrDefault("Operation")
  valid_611295 = validateParameter(valid_611295, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_611295 != nil:
    section.add "Operation", valid_611295
  var valid_611296 = query.getOrDefault("Version")
  valid_611296 = validateParameter(valid_611296, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611296 != nil:
    section.add "Version", valid_611296
  var valid_611297 = query.getOrDefault("SignatureVersion")
  valid_611297 = validateParameter(valid_611297, JString, required = true,
                                 default = nil)
  if valid_611297 != nil:
    section.add "SignatureVersion", valid_611297
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   ManifestAddendum: JString
  ##                   : For internal use only.
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ValidateOnly` field"
  var valid_611298 = formData.getOrDefault("ValidateOnly")
  valid_611298 = validateParameter(valid_611298, JBool, required = true, default = nil)
  if valid_611298 != nil:
    section.add "ValidateOnly", valid_611298
  var valid_611299 = formData.getOrDefault("APIVersion")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "APIVersion", valid_611299
  var valid_611300 = formData.getOrDefault("ManifestAddendum")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "ManifestAddendum", valid_611300
  var valid_611301 = formData.getOrDefault("JobType")
  valid_611301 = validateParameter(valid_611301, JString, required = true,
                                 default = newJString("Import"))
  if valid_611301 != nil:
    section.add "JobType", valid_611301
  var valid_611302 = formData.getOrDefault("Manifest")
  valid_611302 = validateParameter(valid_611302, JString, required = true,
                                 default = nil)
  if valid_611302 != nil:
    section.add "Manifest", valid_611302
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611303: Call_PostCreateJob_611287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_611303.validator(path, query, header, formData, body)
  let scheme = call_611303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611303.url(scheme.get, call_611303.host, call_611303.base,
                         call_611303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611303, url, valid)

proc call*(call_611304: Call_PostCreateJob_611287; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; ValidateOnly: bool;
          Timestamp: string; SignatureVersion: string; Manifest: string;
          APIVersion: string = ""; Action: string = "CreateJob";
          ManifestAddendum: string = ""; Operation: string = "CreateJob";
          Version: string = "2010-06-01"; JobType: string = "Import"): Recallable =
  ## postCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   ManifestAddendum: string
  ##                   : For internal use only.
  ##   Operation: string (required)
  ##   Version: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   SignatureVersion: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  var query_611305 = newJObject()
  var formData_611306 = newJObject()
  add(query_611305, "Signature", newJString(Signature))
  add(query_611305, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611305, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611306, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_611306, "APIVersion", newJString(APIVersion))
  add(query_611305, "Timestamp", newJString(Timestamp))
  add(query_611305, "Action", newJString(Action))
  add(formData_611306, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_611305, "Operation", newJString(Operation))
  add(query_611305, "Version", newJString(Version))
  add(formData_611306, "JobType", newJString(JobType))
  add(query_611305, "SignatureVersion", newJString(SignatureVersion))
  add(formData_611306, "Manifest", newJString(Manifest))
  result = call_611304.call(nil, query_611305, nil, formData_611306, nil)

var postCreateJob* = Call_PostCreateJob_611287(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_611288, base: "/", url: url_PostCreateJob_611289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_611268 = ref object of OpenApiRestCall_610642
proc url_GetCreateJob_611270(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateJob_611269(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   ManifestAddendum: JString
  ##                   : For internal use only.
  ##   Operation: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611271 = query.getOrDefault("Signature")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = nil)
  if valid_611271 != nil:
    section.add "Signature", valid_611271
  var valid_611272 = query.getOrDefault("JobType")
  valid_611272 = validateParameter(valid_611272, JString, required = true,
                                 default = newJString("Import"))
  if valid_611272 != nil:
    section.add "JobType", valid_611272
  var valid_611273 = query.getOrDefault("AWSAccessKeyId")
  valid_611273 = validateParameter(valid_611273, JString, required = true,
                                 default = nil)
  if valid_611273 != nil:
    section.add "AWSAccessKeyId", valid_611273
  var valid_611274 = query.getOrDefault("SignatureMethod")
  valid_611274 = validateParameter(valid_611274, JString, required = true,
                                 default = nil)
  if valid_611274 != nil:
    section.add "SignatureMethod", valid_611274
  var valid_611275 = query.getOrDefault("Manifest")
  valid_611275 = validateParameter(valid_611275, JString, required = true,
                                 default = nil)
  if valid_611275 != nil:
    section.add "Manifest", valid_611275
  var valid_611276 = query.getOrDefault("ValidateOnly")
  valid_611276 = validateParameter(valid_611276, JBool, required = true, default = nil)
  if valid_611276 != nil:
    section.add "ValidateOnly", valid_611276
  var valid_611277 = query.getOrDefault("Timestamp")
  valid_611277 = validateParameter(valid_611277, JString, required = true,
                                 default = nil)
  if valid_611277 != nil:
    section.add "Timestamp", valid_611277
  var valid_611278 = query.getOrDefault("Action")
  valid_611278 = validateParameter(valid_611278, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_611278 != nil:
    section.add "Action", valid_611278
  var valid_611279 = query.getOrDefault("ManifestAddendum")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "ManifestAddendum", valid_611279
  var valid_611280 = query.getOrDefault("Operation")
  valid_611280 = validateParameter(valid_611280, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_611280 != nil:
    section.add "Operation", valid_611280
  var valid_611281 = query.getOrDefault("APIVersion")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "APIVersion", valid_611281
  var valid_611282 = query.getOrDefault("Version")
  valid_611282 = validateParameter(valid_611282, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611282 != nil:
    section.add "Version", valid_611282
  var valid_611283 = query.getOrDefault("SignatureVersion")
  valid_611283 = validateParameter(valid_611283, JString, required = true,
                                 default = nil)
  if valid_611283 != nil:
    section.add "SignatureVersion", valid_611283
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611284: Call_GetCreateJob_611268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_611284.validator(path, query, header, formData, body)
  let scheme = call_611284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611284.url(scheme.get, call_611284.host, call_611284.base,
                         call_611284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611284, url, valid)

proc call*(call_611285: Call_GetCreateJob_611268; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Manifest: string;
          ValidateOnly: bool; Timestamp: string; SignatureVersion: string;
          JobType: string = "Import"; Action: string = "CreateJob";
          ManifestAddendum: string = ""; Operation: string = "CreateJob";
          APIVersion: string = ""; Version: string = "2010-06-01"): Recallable =
  ## getCreateJob
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ##   Signature: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   ManifestAddendum: string
  ##                   : For internal use only.
  ##   Operation: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_611286 = newJObject()
  add(query_611286, "Signature", newJString(Signature))
  add(query_611286, "JobType", newJString(JobType))
  add(query_611286, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611286, "SignatureMethod", newJString(SignatureMethod))
  add(query_611286, "Manifest", newJString(Manifest))
  add(query_611286, "ValidateOnly", newJBool(ValidateOnly))
  add(query_611286, "Timestamp", newJString(Timestamp))
  add(query_611286, "Action", newJString(Action))
  add(query_611286, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_611286, "Operation", newJString(Operation))
  add(query_611286, "APIVersion", newJString(APIVersion))
  add(query_611286, "Version", newJString(Version))
  add(query_611286, "SignatureVersion", newJString(SignatureVersion))
  result = call_611285.call(nil, query_611286, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_611268(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_611269, base: "/", url: url_GetCreateJob_611270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_611333 = ref object of OpenApiRestCall_610642
proc url_PostGetShippingLabel_611335(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetShippingLabel_611334(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611336 = query.getOrDefault("Signature")
  valid_611336 = validateParameter(valid_611336, JString, required = true,
                                 default = nil)
  if valid_611336 != nil:
    section.add "Signature", valid_611336
  var valid_611337 = query.getOrDefault("AWSAccessKeyId")
  valid_611337 = validateParameter(valid_611337, JString, required = true,
                                 default = nil)
  if valid_611337 != nil:
    section.add "AWSAccessKeyId", valid_611337
  var valid_611338 = query.getOrDefault("SignatureMethod")
  valid_611338 = validateParameter(valid_611338, JString, required = true,
                                 default = nil)
  if valid_611338 != nil:
    section.add "SignatureMethod", valid_611338
  var valid_611339 = query.getOrDefault("Timestamp")
  valid_611339 = validateParameter(valid_611339, JString, required = true,
                                 default = nil)
  if valid_611339 != nil:
    section.add "Timestamp", valid_611339
  var valid_611340 = query.getOrDefault("Action")
  valid_611340 = validateParameter(valid_611340, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_611340 != nil:
    section.add "Action", valid_611340
  var valid_611341 = query.getOrDefault("Operation")
  valid_611341 = validateParameter(valid_611341, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_611341 != nil:
    section.add "Operation", valid_611341
  var valid_611342 = query.getOrDefault("Version")
  valid_611342 = validateParameter(valid_611342, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611342 != nil:
    section.add "Version", valid_611342
  var valid_611343 = query.getOrDefault("SignatureVersion")
  valid_611343 = validateParameter(valid_611343, JString, required = true,
                                 default = nil)
  if valid_611343 != nil:
    section.add "SignatureVersion", valid_611343
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   street1: JString
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   stateOrProvince: JString
  ##                  : Specifies the name of your state or your province for the return address.
  ##   street3: JString
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   phoneNumber: JString
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   postalCode: JString
  ##             : Specifies the postal code for the return address.
  ##   jobIds: JArray (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   country: JString
  ##          : Specifies the name of your country for the return address.
  ##   city: JString
  ##       : Specifies the name of your city for the return address.
  ##   street2: JString
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   company: JString
  ##          : Specifies the name of the company that will ship this package.
  ##   name: JString
  ##       : Specifies the name of the person responsible for shipping this package.
  section = newJObject()
  var valid_611344 = formData.getOrDefault("street1")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "street1", valid_611344
  var valid_611345 = formData.getOrDefault("stateOrProvince")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "stateOrProvince", valid_611345
  var valid_611346 = formData.getOrDefault("street3")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "street3", valid_611346
  var valid_611347 = formData.getOrDefault("phoneNumber")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "phoneNumber", valid_611347
  var valid_611348 = formData.getOrDefault("postalCode")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "postalCode", valid_611348
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_611349 = formData.getOrDefault("jobIds")
  valid_611349 = validateParameter(valid_611349, JArray, required = true, default = nil)
  if valid_611349 != nil:
    section.add "jobIds", valid_611349
  var valid_611350 = formData.getOrDefault("APIVersion")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "APIVersion", valid_611350
  var valid_611351 = formData.getOrDefault("country")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "country", valid_611351
  var valid_611352 = formData.getOrDefault("city")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "city", valid_611352
  var valid_611353 = formData.getOrDefault("street2")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "street2", valid_611353
  var valid_611354 = formData.getOrDefault("company")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "company", valid_611354
  var valid_611355 = formData.getOrDefault("name")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "name", valid_611355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611356: Call_PostGetShippingLabel_611333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_611356.validator(path, query, header, formData, body)
  let scheme = call_611356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611356.url(scheme.get, call_611356.host, call_611356.base,
                         call_611356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611356, url, valid)

proc call*(call_611357: Call_PostGetShippingLabel_611333; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; jobIds: JsonNode;
          Timestamp: string; SignatureVersion: string; street1: string = "";
          stateOrProvince: string = ""; street3: string = ""; phoneNumber: string = "";
          postalCode: string = ""; APIVersion: string = ""; country: string = "";
          city: string = ""; street2: string = ""; Action: string = "GetShippingLabel";
          Operation: string = "GetShippingLabel"; company: string = "";
          Version: string = "2010-06-01"; name: string = ""): Recallable =
  ## postGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   street1: string
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   SignatureMethod: string (required)
  ##   stateOrProvince: string
  ##                  : Specifies the name of your state or your province for the return address.
  ##   street3: string
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   phoneNumber: string
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   postalCode: string
  ##             : Specifies the postal code for the return address.
  ##   jobIds: JArray (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   country: string
  ##          : Specifies the name of your country for the return address.
  ##   city: string
  ##       : Specifies the name of your city for the return address.
  ##   street2: string
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   company: string
  ##          : Specifies the name of the company that will ship this package.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  ##   name: string
  ##       : Specifies the name of the person responsible for shipping this package.
  var query_611358 = newJObject()
  var formData_611359 = newJObject()
  add(query_611358, "Signature", newJString(Signature))
  add(query_611358, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_611359, "street1", newJString(street1))
  add(query_611358, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611359, "stateOrProvince", newJString(stateOrProvince))
  add(formData_611359, "street3", newJString(street3))
  add(formData_611359, "phoneNumber", newJString(phoneNumber))
  add(formData_611359, "postalCode", newJString(postalCode))
  if jobIds != nil:
    formData_611359.add "jobIds", jobIds
  add(formData_611359, "APIVersion", newJString(APIVersion))
  add(formData_611359, "country", newJString(country))
  add(formData_611359, "city", newJString(city))
  add(formData_611359, "street2", newJString(street2))
  add(query_611358, "Timestamp", newJString(Timestamp))
  add(query_611358, "Action", newJString(Action))
  add(query_611358, "Operation", newJString(Operation))
  add(formData_611359, "company", newJString(company))
  add(query_611358, "Version", newJString(Version))
  add(query_611358, "SignatureVersion", newJString(SignatureVersion))
  add(formData_611359, "name", newJString(name))
  result = call_611357.call(nil, query_611358, nil, formData_611359, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_611333(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_611334, base: "/",
    url: url_PostGetShippingLabel_611335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_611307 = ref object of OpenApiRestCall_610642
proc url_GetGetShippingLabel_611309(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetShippingLabel_611308(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   name: JString
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   street2: JString
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   street3: JString
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   phoneNumber: JString
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   postalCode: JString
  ##             : Specifies the postal code for the return address.
  ##   street1: JString
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   city: JString
  ##       : Specifies the name of your city for the return address.
  ##   country: JString
  ##          : Specifies the name of your country for the return address.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   jobIds: JArray (required)
  ##   Operation: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Version: JString (required)
  ##   stateOrProvince: JString
  ##                  : Specifies the name of your state or your province for the return address.
  ##   SignatureVersion: JString (required)
  ##   company: JString
  ##          : Specifies the name of the company that will ship this package.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611310 = query.getOrDefault("Signature")
  valid_611310 = validateParameter(valid_611310, JString, required = true,
                                 default = nil)
  if valid_611310 != nil:
    section.add "Signature", valid_611310
  var valid_611311 = query.getOrDefault("name")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "name", valid_611311
  var valid_611312 = query.getOrDefault("street2")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "street2", valid_611312
  var valid_611313 = query.getOrDefault("street3")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "street3", valid_611313
  var valid_611314 = query.getOrDefault("AWSAccessKeyId")
  valid_611314 = validateParameter(valid_611314, JString, required = true,
                                 default = nil)
  if valid_611314 != nil:
    section.add "AWSAccessKeyId", valid_611314
  var valid_611315 = query.getOrDefault("SignatureMethod")
  valid_611315 = validateParameter(valid_611315, JString, required = true,
                                 default = nil)
  if valid_611315 != nil:
    section.add "SignatureMethod", valid_611315
  var valid_611316 = query.getOrDefault("phoneNumber")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "phoneNumber", valid_611316
  var valid_611317 = query.getOrDefault("postalCode")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "postalCode", valid_611317
  var valid_611318 = query.getOrDefault("street1")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "street1", valid_611318
  var valid_611319 = query.getOrDefault("city")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "city", valid_611319
  var valid_611320 = query.getOrDefault("country")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "country", valid_611320
  var valid_611321 = query.getOrDefault("Timestamp")
  valid_611321 = validateParameter(valid_611321, JString, required = true,
                                 default = nil)
  if valid_611321 != nil:
    section.add "Timestamp", valid_611321
  var valid_611322 = query.getOrDefault("Action")
  valid_611322 = validateParameter(valid_611322, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_611322 != nil:
    section.add "Action", valid_611322
  var valid_611323 = query.getOrDefault("jobIds")
  valid_611323 = validateParameter(valid_611323, JArray, required = true, default = nil)
  if valid_611323 != nil:
    section.add "jobIds", valid_611323
  var valid_611324 = query.getOrDefault("Operation")
  valid_611324 = validateParameter(valid_611324, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_611324 != nil:
    section.add "Operation", valid_611324
  var valid_611325 = query.getOrDefault("APIVersion")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "APIVersion", valid_611325
  var valid_611326 = query.getOrDefault("Version")
  valid_611326 = validateParameter(valid_611326, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611326 != nil:
    section.add "Version", valid_611326
  var valid_611327 = query.getOrDefault("stateOrProvince")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "stateOrProvince", valid_611327
  var valid_611328 = query.getOrDefault("SignatureVersion")
  valid_611328 = validateParameter(valid_611328, JString, required = true,
                                 default = nil)
  if valid_611328 != nil:
    section.add "SignatureVersion", valid_611328
  var valid_611329 = query.getOrDefault("company")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "company", valid_611329
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611330: Call_GetGetShippingLabel_611307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_611330.validator(path, query, header, formData, body)
  let scheme = call_611330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611330.url(scheme.get, call_611330.host, call_611330.base,
                         call_611330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611330, url, valid)

proc call*(call_611331: Call_GetGetShippingLabel_611307; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          jobIds: JsonNode; SignatureVersion: string; name: string = "";
          street2: string = ""; street3: string = ""; phoneNumber: string = "";
          postalCode: string = ""; street1: string = ""; city: string = "";
          country: string = ""; Action: string = "GetShippingLabel";
          Operation: string = "GetShippingLabel"; APIVersion: string = "";
          Version: string = "2010-06-01"; stateOrProvince: string = "";
          company: string = ""): Recallable =
  ## getGetShippingLabel
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ##   Signature: string (required)
  ##   name: string
  ##       : Specifies the name of the person responsible for shipping this package.
  ##   street2: string
  ##          : Specifies the optional second part of the street address for the return address, for example Suite 100.
  ##   street3: string
  ##          : Specifies the optional third part of the street address for the return address, for example c/o Jane Doe.
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   phoneNumber: string
  ##              : Specifies the phone number of the person responsible for shipping this package.
  ##   postalCode: string
  ##             : Specifies the postal code for the return address.
  ##   street1: string
  ##          : Specifies the first part of the street address for the return address, for example 1234 Main Street.
  ##   city: string
  ##       : Specifies the name of your city for the return address.
  ##   country: string
  ##          : Specifies the name of your country for the return address.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   jobIds: JArray (required)
  ##   Operation: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Version: string (required)
  ##   stateOrProvince: string
  ##                  : Specifies the name of your state or your province for the return address.
  ##   SignatureVersion: string (required)
  ##   company: string
  ##          : Specifies the name of the company that will ship this package.
  var query_611332 = newJObject()
  add(query_611332, "Signature", newJString(Signature))
  add(query_611332, "name", newJString(name))
  add(query_611332, "street2", newJString(street2))
  add(query_611332, "street3", newJString(street3))
  add(query_611332, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611332, "SignatureMethod", newJString(SignatureMethod))
  add(query_611332, "phoneNumber", newJString(phoneNumber))
  add(query_611332, "postalCode", newJString(postalCode))
  add(query_611332, "street1", newJString(street1))
  add(query_611332, "city", newJString(city))
  add(query_611332, "country", newJString(country))
  add(query_611332, "Timestamp", newJString(Timestamp))
  add(query_611332, "Action", newJString(Action))
  if jobIds != nil:
    query_611332.add "jobIds", jobIds
  add(query_611332, "Operation", newJString(Operation))
  add(query_611332, "APIVersion", newJString(APIVersion))
  add(query_611332, "Version", newJString(Version))
  add(query_611332, "stateOrProvince", newJString(stateOrProvince))
  add(query_611332, "SignatureVersion", newJString(SignatureVersion))
  add(query_611332, "company", newJString(company))
  result = call_611331.call(nil, query_611332, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_611307(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_611308, base: "/",
    url: url_GetGetShippingLabel_611309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_611376 = ref object of OpenApiRestCall_610642
proc url_PostGetStatus_611378(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetStatus_611377(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611379 = query.getOrDefault("Signature")
  valid_611379 = validateParameter(valid_611379, JString, required = true,
                                 default = nil)
  if valid_611379 != nil:
    section.add "Signature", valid_611379
  var valid_611380 = query.getOrDefault("AWSAccessKeyId")
  valid_611380 = validateParameter(valid_611380, JString, required = true,
                                 default = nil)
  if valid_611380 != nil:
    section.add "AWSAccessKeyId", valid_611380
  var valid_611381 = query.getOrDefault("SignatureMethod")
  valid_611381 = validateParameter(valid_611381, JString, required = true,
                                 default = nil)
  if valid_611381 != nil:
    section.add "SignatureMethod", valid_611381
  var valid_611382 = query.getOrDefault("Timestamp")
  valid_611382 = validateParameter(valid_611382, JString, required = true,
                                 default = nil)
  if valid_611382 != nil:
    section.add "Timestamp", valid_611382
  var valid_611383 = query.getOrDefault("Action")
  valid_611383 = validateParameter(valid_611383, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_611383 != nil:
    section.add "Action", valid_611383
  var valid_611384 = query.getOrDefault("Operation")
  valid_611384 = validateParameter(valid_611384, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_611384 != nil:
    section.add "Operation", valid_611384
  var valid_611385 = query.getOrDefault("Version")
  valid_611385 = validateParameter(valid_611385, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611385 != nil:
    section.add "Version", valid_611385
  var valid_611386 = query.getOrDefault("SignatureVersion")
  valid_611386 = validateParameter(valid_611386, JString, required = true,
                                 default = nil)
  if valid_611386 != nil:
    section.add "SignatureVersion", valid_611386
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_611387 = formData.getOrDefault("APIVersion")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "APIVersion", valid_611387
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_611388 = formData.getOrDefault("JobId")
  valid_611388 = validateParameter(valid_611388, JString, required = true,
                                 default = nil)
  if valid_611388 != nil:
    section.add "JobId", valid_611388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611389: Call_PostGetStatus_611376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_PostGetStatus_611376; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          JobId: string; SignatureVersion: string; APIVersion: string = "";
          Action: string = "GetStatus"; Operation: string = "GetStatus";
          Version: string = "2010-06-01"): Recallable =
  ## postGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_611391 = newJObject()
  var formData_611392 = newJObject()
  add(query_611391, "Signature", newJString(Signature))
  add(query_611391, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611391, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611392, "APIVersion", newJString(APIVersion))
  add(query_611391, "Timestamp", newJString(Timestamp))
  add(query_611391, "Action", newJString(Action))
  add(query_611391, "Operation", newJString(Operation))
  add(formData_611392, "JobId", newJString(JobId))
  add(query_611391, "Version", newJString(Version))
  add(query_611391, "SignatureVersion", newJString(SignatureVersion))
  result = call_611390.call(nil, query_611391, nil, formData_611392, nil)

var postGetStatus* = Call_PostGetStatus_611376(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_611377, base: "/", url: url_PostGetStatus_611378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_611360 = ref object of OpenApiRestCall_610642
proc url_GetGetStatus_611362(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetStatus_611361(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Version: JString (required)
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611363 = query.getOrDefault("Signature")
  valid_611363 = validateParameter(valid_611363, JString, required = true,
                                 default = nil)
  if valid_611363 != nil:
    section.add "Signature", valid_611363
  var valid_611364 = query.getOrDefault("AWSAccessKeyId")
  valid_611364 = validateParameter(valid_611364, JString, required = true,
                                 default = nil)
  if valid_611364 != nil:
    section.add "AWSAccessKeyId", valid_611364
  var valid_611365 = query.getOrDefault("SignatureMethod")
  valid_611365 = validateParameter(valid_611365, JString, required = true,
                                 default = nil)
  if valid_611365 != nil:
    section.add "SignatureMethod", valid_611365
  var valid_611366 = query.getOrDefault("Timestamp")
  valid_611366 = validateParameter(valid_611366, JString, required = true,
                                 default = nil)
  if valid_611366 != nil:
    section.add "Timestamp", valid_611366
  var valid_611367 = query.getOrDefault("Action")
  valid_611367 = validateParameter(valid_611367, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_611367 != nil:
    section.add "Action", valid_611367
  var valid_611368 = query.getOrDefault("Operation")
  valid_611368 = validateParameter(valid_611368, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_611368 != nil:
    section.add "Operation", valid_611368
  var valid_611369 = query.getOrDefault("APIVersion")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "APIVersion", valid_611369
  var valid_611370 = query.getOrDefault("Version")
  valid_611370 = validateParameter(valid_611370, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611370 != nil:
    section.add "Version", valid_611370
  var valid_611371 = query.getOrDefault("JobId")
  valid_611371 = validateParameter(valid_611371, JString, required = true,
                                 default = nil)
  if valid_611371 != nil:
    section.add "JobId", valid_611371
  var valid_611372 = query.getOrDefault("SignatureVersion")
  valid_611372 = validateParameter(valid_611372, JString, required = true,
                                 default = nil)
  if valid_611372 != nil:
    section.add "SignatureVersion", valid_611372
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611373: Call_GetGetStatus_611360; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_611373.validator(path, query, header, formData, body)
  let scheme = call_611373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611373.url(scheme.get, call_611373.host, call_611373.base,
                         call_611373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611373, url, valid)

proc call*(call_611374: Call_GetGetStatus_611360; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          JobId: string; SignatureVersion: string; Action: string = "GetStatus";
          Operation: string = "GetStatus"; APIVersion: string = "";
          Version: string = "2010-06-01"): Recallable =
  ## getGetStatus
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Version: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   SignatureVersion: string (required)
  var query_611375 = newJObject()
  add(query_611375, "Signature", newJString(Signature))
  add(query_611375, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611375, "SignatureMethod", newJString(SignatureMethod))
  add(query_611375, "Timestamp", newJString(Timestamp))
  add(query_611375, "Action", newJString(Action))
  add(query_611375, "Operation", newJString(Operation))
  add(query_611375, "APIVersion", newJString(APIVersion))
  add(query_611375, "Version", newJString(Version))
  add(query_611375, "JobId", newJString(JobId))
  add(query_611375, "SignatureVersion", newJString(SignatureVersion))
  result = call_611374.call(nil, query_611375, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_611360(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_611361, base: "/", url: url_GetGetStatus_611362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_611410 = ref object of OpenApiRestCall_610642
proc url_PostListJobs_611412(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListJobs_611411(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611413 = query.getOrDefault("Signature")
  valid_611413 = validateParameter(valid_611413, JString, required = true,
                                 default = nil)
  if valid_611413 != nil:
    section.add "Signature", valid_611413
  var valid_611414 = query.getOrDefault("AWSAccessKeyId")
  valid_611414 = validateParameter(valid_611414, JString, required = true,
                                 default = nil)
  if valid_611414 != nil:
    section.add "AWSAccessKeyId", valid_611414
  var valid_611415 = query.getOrDefault("SignatureMethod")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "SignatureMethod", valid_611415
  var valid_611416 = query.getOrDefault("Timestamp")
  valid_611416 = validateParameter(valid_611416, JString, required = true,
                                 default = nil)
  if valid_611416 != nil:
    section.add "Timestamp", valid_611416
  var valid_611417 = query.getOrDefault("Action")
  valid_611417 = validateParameter(valid_611417, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_611417 != nil:
    section.add "Action", valid_611417
  var valid_611418 = query.getOrDefault("Operation")
  valid_611418 = validateParameter(valid_611418, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_611418 != nil:
    section.add "Operation", valid_611418
  var valid_611419 = query.getOrDefault("Version")
  valid_611419 = validateParameter(valid_611419, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611419 != nil:
    section.add "Version", valid_611419
  var valid_611420 = query.getOrDefault("SignatureVersion")
  valid_611420 = validateParameter(valid_611420, JString, required = true,
                                 default = nil)
  if valid_611420 != nil:
    section.add "SignatureVersion", valid_611420
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   MaxJobs: JInt
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Marker: JString
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  section = newJObject()
  var valid_611421 = formData.getOrDefault("MaxJobs")
  valid_611421 = validateParameter(valid_611421, JInt, required = false, default = nil)
  if valid_611421 != nil:
    section.add "MaxJobs", valid_611421
  var valid_611422 = formData.getOrDefault("Marker")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "Marker", valid_611422
  var valid_611423 = formData.getOrDefault("APIVersion")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "APIVersion", valid_611423
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611424: Call_PostListJobs_611410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_611424.validator(path, query, header, formData, body)
  let scheme = call_611424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611424.url(scheme.get, call_611424.host, call_611424.base,
                         call_611424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611424, url, valid)

proc call*(call_611425: Call_PostListJobs_611410; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          SignatureVersion: string; MaxJobs: int = 0; Marker: string = "";
          APIVersion: string = ""; Action: string = "ListJobs";
          Operation: string = "ListJobs"; Version: string = "2010-06-01"): Recallable =
  ## postListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   Signature: string (required)
  ##   MaxJobs: int
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   Marker: string
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_611426 = newJObject()
  var formData_611427 = newJObject()
  add(query_611426, "Signature", newJString(Signature))
  add(formData_611427, "MaxJobs", newJInt(MaxJobs))
  add(query_611426, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611426, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611427, "Marker", newJString(Marker))
  add(formData_611427, "APIVersion", newJString(APIVersion))
  add(query_611426, "Timestamp", newJString(Timestamp))
  add(query_611426, "Action", newJString(Action))
  add(query_611426, "Operation", newJString(Operation))
  add(query_611426, "Version", newJString(Version))
  add(query_611426, "SignatureVersion", newJString(SignatureVersion))
  result = call_611425.call(nil, query_611426, nil, formData_611427, nil)

var postListJobs* = Call_PostListJobs_611410(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_611411, base: "/", url: url_PostListJobs_611412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_611393 = ref object of OpenApiRestCall_610642
proc url_GetListJobs_611395(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListJobs_611394(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxJobs: JInt
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Marker: JString
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  var valid_611396 = query.getOrDefault("MaxJobs")
  valid_611396 = validateParameter(valid_611396, JInt, required = false, default = nil)
  if valid_611396 != nil:
    section.add "MaxJobs", valid_611396
  var valid_611397 = query.getOrDefault("Marker")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "Marker", valid_611397
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611398 = query.getOrDefault("Signature")
  valid_611398 = validateParameter(valid_611398, JString, required = true,
                                 default = nil)
  if valid_611398 != nil:
    section.add "Signature", valid_611398
  var valid_611399 = query.getOrDefault("AWSAccessKeyId")
  valid_611399 = validateParameter(valid_611399, JString, required = true,
                                 default = nil)
  if valid_611399 != nil:
    section.add "AWSAccessKeyId", valid_611399
  var valid_611400 = query.getOrDefault("SignatureMethod")
  valid_611400 = validateParameter(valid_611400, JString, required = true,
                                 default = nil)
  if valid_611400 != nil:
    section.add "SignatureMethod", valid_611400
  var valid_611401 = query.getOrDefault("Timestamp")
  valid_611401 = validateParameter(valid_611401, JString, required = true,
                                 default = nil)
  if valid_611401 != nil:
    section.add "Timestamp", valid_611401
  var valid_611402 = query.getOrDefault("Action")
  valid_611402 = validateParameter(valid_611402, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_611402 != nil:
    section.add "Action", valid_611402
  var valid_611403 = query.getOrDefault("Operation")
  valid_611403 = validateParameter(valid_611403, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_611403 != nil:
    section.add "Operation", valid_611403
  var valid_611404 = query.getOrDefault("APIVersion")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "APIVersion", valid_611404
  var valid_611405 = query.getOrDefault("Version")
  valid_611405 = validateParameter(valid_611405, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611405 != nil:
    section.add "Version", valid_611405
  var valid_611406 = query.getOrDefault("SignatureVersion")
  valid_611406 = validateParameter(valid_611406, JString, required = true,
                                 default = nil)
  if valid_611406 != nil:
    section.add "SignatureVersion", valid_611406
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611407: Call_GetListJobs_611393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_611407.validator(path, query, header, formData, body)
  let scheme = call_611407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611407.url(scheme.get, call_611407.host, call_611407.base,
                         call_611407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611407, url, valid)

proc call*(call_611408: Call_GetListJobs_611393; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Timestamp: string;
          SignatureVersion: string; MaxJobs: int = 0; Marker: string = "";
          Action: string = "ListJobs"; Operation: string = "ListJobs";
          APIVersion: string = ""; Version: string = "2010-06-01"): Recallable =
  ## getListJobs
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ##   MaxJobs: int
  ##          : Sets the maximum number of jobs returned in the response. If there are additional jobs that were not returned because MaxJobs was exceeded, the response contains &lt;IsTruncated&gt;true&lt;/IsTruncated&gt;. To return the additional jobs, see Marker.
  ##   Marker: string
  ##         : Specifies the JOBID to start after when listing the jobs created with your account. AWS Import/Export lists your jobs in reverse chronological order. See MaxJobs.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Version: string (required)
  ##   SignatureVersion: string (required)
  var query_611409 = newJObject()
  add(query_611409, "MaxJobs", newJInt(MaxJobs))
  add(query_611409, "Marker", newJString(Marker))
  add(query_611409, "Signature", newJString(Signature))
  add(query_611409, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611409, "SignatureMethod", newJString(SignatureMethod))
  add(query_611409, "Timestamp", newJString(Timestamp))
  add(query_611409, "Action", newJString(Action))
  add(query_611409, "Operation", newJString(Operation))
  add(query_611409, "APIVersion", newJString(APIVersion))
  add(query_611409, "Version", newJString(Version))
  add(query_611409, "SignatureVersion", newJString(SignatureVersion))
  result = call_611408.call(nil, query_611409, nil, nil, nil)

var getListJobs* = Call_GetListJobs_611393(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_611394,
                                        base: "/", url: url_GetListJobs_611395,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_611447 = ref object of OpenApiRestCall_610642
proc url_PostUpdateJob_611449(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateJob_611448(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   Version: JString (required)
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611450 = query.getOrDefault("Signature")
  valid_611450 = validateParameter(valid_611450, JString, required = true,
                                 default = nil)
  if valid_611450 != nil:
    section.add "Signature", valid_611450
  var valid_611451 = query.getOrDefault("AWSAccessKeyId")
  valid_611451 = validateParameter(valid_611451, JString, required = true,
                                 default = nil)
  if valid_611451 != nil:
    section.add "AWSAccessKeyId", valid_611451
  var valid_611452 = query.getOrDefault("SignatureMethod")
  valid_611452 = validateParameter(valid_611452, JString, required = true,
                                 default = nil)
  if valid_611452 != nil:
    section.add "SignatureMethod", valid_611452
  var valid_611453 = query.getOrDefault("Timestamp")
  valid_611453 = validateParameter(valid_611453, JString, required = true,
                                 default = nil)
  if valid_611453 != nil:
    section.add "Timestamp", valid_611453
  var valid_611454 = query.getOrDefault("Action")
  valid_611454 = validateParameter(valid_611454, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_611454 != nil:
    section.add "Action", valid_611454
  var valid_611455 = query.getOrDefault("Operation")
  valid_611455 = validateParameter(valid_611455, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_611455 != nil:
    section.add "Operation", valid_611455
  var valid_611456 = query.getOrDefault("Version")
  valid_611456 = validateParameter(valid_611456, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611456 != nil:
    section.add "Version", valid_611456
  var valid_611457 = query.getOrDefault("SignatureVersion")
  valid_611457 = validateParameter(valid_611457, JString, required = true,
                                 default = nil)
  if valid_611457 != nil:
    section.add "SignatureVersion", valid_611457
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ValidateOnly` field"
  var valid_611458 = formData.getOrDefault("ValidateOnly")
  valid_611458 = validateParameter(valid_611458, JBool, required = true, default = nil)
  if valid_611458 != nil:
    section.add "ValidateOnly", valid_611458
  var valid_611459 = formData.getOrDefault("APIVersion")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "APIVersion", valid_611459
  var valid_611460 = formData.getOrDefault("JobId")
  valid_611460 = validateParameter(valid_611460, JString, required = true,
                                 default = nil)
  if valid_611460 != nil:
    section.add "JobId", valid_611460
  var valid_611461 = formData.getOrDefault("JobType")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = newJString("Import"))
  if valid_611461 != nil:
    section.add "JobType", valid_611461
  var valid_611462 = formData.getOrDefault("Manifest")
  valid_611462 = validateParameter(valid_611462, JString, required = true,
                                 default = nil)
  if valid_611462 != nil:
    section.add "Manifest", valid_611462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611463: Call_PostUpdateJob_611447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_611463.validator(path, query, header, formData, body)
  let scheme = call_611463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611463.url(scheme.get, call_611463.host, call_611463.base,
                         call_611463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611463, url, valid)

proc call*(call_611464: Call_PostUpdateJob_611447; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; ValidateOnly: bool;
          Timestamp: string; JobId: string; SignatureVersion: string;
          Manifest: string; APIVersion: string = ""; Action: string = "UpdateJob";
          Operation: string = "UpdateJob"; Version: string = "2010-06-01";
          JobType: string = "Import"): Recallable =
  ## postUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   Signature: string (required)
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   Version: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   SignatureVersion: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  var query_611465 = newJObject()
  var formData_611466 = newJObject()
  add(query_611465, "Signature", newJString(Signature))
  add(query_611465, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611465, "SignatureMethod", newJString(SignatureMethod))
  add(formData_611466, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_611466, "APIVersion", newJString(APIVersion))
  add(query_611465, "Timestamp", newJString(Timestamp))
  add(query_611465, "Action", newJString(Action))
  add(query_611465, "Operation", newJString(Operation))
  add(formData_611466, "JobId", newJString(JobId))
  add(query_611465, "Version", newJString(Version))
  add(formData_611466, "JobType", newJString(JobType))
  add(query_611465, "SignatureVersion", newJString(SignatureVersion))
  add(formData_611466, "Manifest", newJString(Manifest))
  result = call_611464.call(nil, query_611465, nil, formData_611466, nil)

var postUpdateJob* = Call_PostUpdateJob_611447(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_611448, base: "/", url: url_PostUpdateJob_611449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_611428 = ref object of OpenApiRestCall_610642
proc url_GetUpdateJob_611430(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateJob_611429(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Signature: JString (required)
  ##   JobType: JString (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   AWSAccessKeyId: JString (required)
  ##   SignatureMethod: JString (required)
  ##   Manifest: JString (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   ValidateOnly: JBool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: JString (required)
  ##   Action: JString (required)
  ##   Operation: JString (required)
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   Version: JString (required)
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  ##   SignatureVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_611431 = query.getOrDefault("Signature")
  valid_611431 = validateParameter(valid_611431, JString, required = true,
                                 default = nil)
  if valid_611431 != nil:
    section.add "Signature", valid_611431
  var valid_611432 = query.getOrDefault("JobType")
  valid_611432 = validateParameter(valid_611432, JString, required = true,
                                 default = newJString("Import"))
  if valid_611432 != nil:
    section.add "JobType", valid_611432
  var valid_611433 = query.getOrDefault("AWSAccessKeyId")
  valid_611433 = validateParameter(valid_611433, JString, required = true,
                                 default = nil)
  if valid_611433 != nil:
    section.add "AWSAccessKeyId", valid_611433
  var valid_611434 = query.getOrDefault("SignatureMethod")
  valid_611434 = validateParameter(valid_611434, JString, required = true,
                                 default = nil)
  if valid_611434 != nil:
    section.add "SignatureMethod", valid_611434
  var valid_611435 = query.getOrDefault("Manifest")
  valid_611435 = validateParameter(valid_611435, JString, required = true,
                                 default = nil)
  if valid_611435 != nil:
    section.add "Manifest", valid_611435
  var valid_611436 = query.getOrDefault("ValidateOnly")
  valid_611436 = validateParameter(valid_611436, JBool, required = true, default = nil)
  if valid_611436 != nil:
    section.add "ValidateOnly", valid_611436
  var valid_611437 = query.getOrDefault("Timestamp")
  valid_611437 = validateParameter(valid_611437, JString, required = true,
                                 default = nil)
  if valid_611437 != nil:
    section.add "Timestamp", valid_611437
  var valid_611438 = query.getOrDefault("Action")
  valid_611438 = validateParameter(valid_611438, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_611438 != nil:
    section.add "Action", valid_611438
  var valid_611439 = query.getOrDefault("Operation")
  valid_611439 = validateParameter(valid_611439, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_611439 != nil:
    section.add "Operation", valid_611439
  var valid_611440 = query.getOrDefault("APIVersion")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "APIVersion", valid_611440
  var valid_611441 = query.getOrDefault("Version")
  valid_611441 = validateParameter(valid_611441, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_611441 != nil:
    section.add "Version", valid_611441
  var valid_611442 = query.getOrDefault("JobId")
  valid_611442 = validateParameter(valid_611442, JString, required = true,
                                 default = nil)
  if valid_611442 != nil:
    section.add "JobId", valid_611442
  var valid_611443 = query.getOrDefault("SignatureVersion")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "SignatureVersion", valid_611443
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611444: Call_GetUpdateJob_611428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_611444.validator(path, query, header, formData, body)
  let scheme = call_611444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611444.url(scheme.get, call_611444.host, call_611444.base,
                         call_611444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611444, url, valid)

proc call*(call_611445: Call_GetUpdateJob_611428; Signature: string;
          AWSAccessKeyId: string; SignatureMethod: string; Manifest: string;
          ValidateOnly: bool; Timestamp: string; JobId: string;
          SignatureVersion: string; JobType: string = "Import";
          Action: string = "UpdateJob"; Operation: string = "UpdateJob";
          APIVersion: string = ""; Version: string = "2010-06-01"): Recallable =
  ## getUpdateJob
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ##   Signature: string (required)
  ##   JobType: string (required)
  ##          : Specifies whether the job to initiate is an import or export job.
  ##   AWSAccessKeyId: string (required)
  ##   SignatureMethod: string (required)
  ##   Manifest: string (required)
  ##           : The UTF-8 encoded text of the manifest file.
  ##   ValidateOnly: bool (required)
  ##               : Validate the manifest and parameter values in the request but do not actually create a job.
  ##   Timestamp: string (required)
  ##   Action: string (required)
  ##   Operation: string (required)
  ##   APIVersion: string
  ##             : Specifies the version of the client tool.
  ##   Version: string (required)
  ##   JobId: string (required)
  ##        : A unique identifier which refers to a particular job.
  ##   SignatureVersion: string (required)
  var query_611446 = newJObject()
  add(query_611446, "Signature", newJString(Signature))
  add(query_611446, "JobType", newJString(JobType))
  add(query_611446, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_611446, "SignatureMethod", newJString(SignatureMethod))
  add(query_611446, "Manifest", newJString(Manifest))
  add(query_611446, "ValidateOnly", newJBool(ValidateOnly))
  add(query_611446, "Timestamp", newJString(Timestamp))
  add(query_611446, "Action", newJString(Action))
  add(query_611446, "Operation", newJString(Operation))
  add(query_611446, "APIVersion", newJString(APIVersion))
  add(query_611446, "Version", newJString(Version))
  add(query_611446, "JobId", newJString(JobId))
  add(query_611446, "SignatureVersion", newJString(SignatureVersion))
  result = call_611445.call(nil, query_611446, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_611428(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_611429, base: "/", url: url_GetUpdateJob_611430,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
