
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

  OpenApiRestCall_612642 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612642](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612642): Option[Scheme] {.used.} =
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
  Call_PostCancelJob_613251 = ref object of OpenApiRestCall_612642
proc url_PostCancelJob_613253(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCancelJob_613252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613254 = query.getOrDefault("Signature")
  valid_613254 = validateParameter(valid_613254, JString, required = true,
                                 default = nil)
  if valid_613254 != nil:
    section.add "Signature", valid_613254
  var valid_613255 = query.getOrDefault("AWSAccessKeyId")
  valid_613255 = validateParameter(valid_613255, JString, required = true,
                                 default = nil)
  if valid_613255 != nil:
    section.add "AWSAccessKeyId", valid_613255
  var valid_613256 = query.getOrDefault("SignatureMethod")
  valid_613256 = validateParameter(valid_613256, JString, required = true,
                                 default = nil)
  if valid_613256 != nil:
    section.add "SignatureMethod", valid_613256
  var valid_613257 = query.getOrDefault("Timestamp")
  valid_613257 = validateParameter(valid_613257, JString, required = true,
                                 default = nil)
  if valid_613257 != nil:
    section.add "Timestamp", valid_613257
  var valid_613258 = query.getOrDefault("Action")
  valid_613258 = validateParameter(valid_613258, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_613258 != nil:
    section.add "Action", valid_613258
  var valid_613259 = query.getOrDefault("Operation")
  valid_613259 = validateParameter(valid_613259, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_613259 != nil:
    section.add "Operation", valid_613259
  var valid_613260 = query.getOrDefault("Version")
  valid_613260 = validateParameter(valid_613260, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613260 != nil:
    section.add "Version", valid_613260
  var valid_613261 = query.getOrDefault("SignatureVersion")
  valid_613261 = validateParameter(valid_613261, JString, required = true,
                                 default = nil)
  if valid_613261 != nil:
    section.add "SignatureVersion", valid_613261
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_613262 = formData.getOrDefault("APIVersion")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "APIVersion", valid_613262
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_613263 = formData.getOrDefault("JobId")
  valid_613263 = validateParameter(valid_613263, JString, required = true,
                                 default = nil)
  if valid_613263 != nil:
    section.add "JobId", valid_613263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613264: Call_PostCancelJob_613251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_613264.validator(path, query, header, formData, body)
  let scheme = call_613264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613264.url(scheme.get, call_613264.host, call_613264.base,
                         call_613264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613264, url, valid)

proc call*(call_613265: Call_PostCancelJob_613251; Signature: string;
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
  var query_613266 = newJObject()
  var formData_613267 = newJObject()
  add(query_613266, "Signature", newJString(Signature))
  add(query_613266, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613266, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613267, "APIVersion", newJString(APIVersion))
  add(query_613266, "Timestamp", newJString(Timestamp))
  add(query_613266, "Action", newJString(Action))
  add(query_613266, "Operation", newJString(Operation))
  add(formData_613267, "JobId", newJString(JobId))
  add(query_613266, "Version", newJString(Version))
  add(query_613266, "SignatureVersion", newJString(SignatureVersion))
  result = call_613265.call(nil, query_613266, nil, formData_613267, nil)

var postCancelJob* = Call_PostCancelJob_613251(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_613252, base: "/", url: url_PostCancelJob_613253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_612980 = ref object of OpenApiRestCall_612642
proc url_GetCancelJob_612982(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCancelJob_612981(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613094 = query.getOrDefault("Signature")
  valid_613094 = validateParameter(valid_613094, JString, required = true,
                                 default = nil)
  if valid_613094 != nil:
    section.add "Signature", valid_613094
  var valid_613095 = query.getOrDefault("AWSAccessKeyId")
  valid_613095 = validateParameter(valid_613095, JString, required = true,
                                 default = nil)
  if valid_613095 != nil:
    section.add "AWSAccessKeyId", valid_613095
  var valid_613096 = query.getOrDefault("SignatureMethod")
  valid_613096 = validateParameter(valid_613096, JString, required = true,
                                 default = nil)
  if valid_613096 != nil:
    section.add "SignatureMethod", valid_613096
  var valid_613097 = query.getOrDefault("Timestamp")
  valid_613097 = validateParameter(valid_613097, JString, required = true,
                                 default = nil)
  if valid_613097 != nil:
    section.add "Timestamp", valid_613097
  var valid_613111 = query.getOrDefault("Action")
  valid_613111 = validateParameter(valid_613111, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_613111 != nil:
    section.add "Action", valid_613111
  var valid_613112 = query.getOrDefault("Operation")
  valid_613112 = validateParameter(valid_613112, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_613112 != nil:
    section.add "Operation", valid_613112
  var valid_613113 = query.getOrDefault("APIVersion")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "APIVersion", valid_613113
  var valid_613114 = query.getOrDefault("Version")
  valid_613114 = validateParameter(valid_613114, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613114 != nil:
    section.add "Version", valid_613114
  var valid_613115 = query.getOrDefault("JobId")
  valid_613115 = validateParameter(valid_613115, JString, required = true,
                                 default = nil)
  if valid_613115 != nil:
    section.add "JobId", valid_613115
  var valid_613116 = query.getOrDefault("SignatureVersion")
  valid_613116 = validateParameter(valid_613116, JString, required = true,
                                 default = nil)
  if valid_613116 != nil:
    section.add "SignatureVersion", valid_613116
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613139: Call_GetCancelJob_612980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_613139.validator(path, query, header, formData, body)
  let scheme = call_613139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613139.url(scheme.get, call_613139.host, call_613139.base,
                         call_613139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613139, url, valid)

proc call*(call_613210: Call_GetCancelJob_612980; Signature: string;
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
  var query_613211 = newJObject()
  add(query_613211, "Signature", newJString(Signature))
  add(query_613211, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613211, "SignatureMethod", newJString(SignatureMethod))
  add(query_613211, "Timestamp", newJString(Timestamp))
  add(query_613211, "Action", newJString(Action))
  add(query_613211, "Operation", newJString(Operation))
  add(query_613211, "APIVersion", newJString(APIVersion))
  add(query_613211, "Version", newJString(Version))
  add(query_613211, "JobId", newJString(JobId))
  add(query_613211, "SignatureVersion", newJString(SignatureVersion))
  result = call_613210.call(nil, query_613211, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_612980(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_612981, base: "/", url: url_GetCancelJob_612982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_613287 = ref object of OpenApiRestCall_612642
proc url_PostCreateJob_613289(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateJob_613288(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613290 = query.getOrDefault("Signature")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "Signature", valid_613290
  var valid_613291 = query.getOrDefault("AWSAccessKeyId")
  valid_613291 = validateParameter(valid_613291, JString, required = true,
                                 default = nil)
  if valid_613291 != nil:
    section.add "AWSAccessKeyId", valid_613291
  var valid_613292 = query.getOrDefault("SignatureMethod")
  valid_613292 = validateParameter(valid_613292, JString, required = true,
                                 default = nil)
  if valid_613292 != nil:
    section.add "SignatureMethod", valid_613292
  var valid_613293 = query.getOrDefault("Timestamp")
  valid_613293 = validateParameter(valid_613293, JString, required = true,
                                 default = nil)
  if valid_613293 != nil:
    section.add "Timestamp", valid_613293
  var valid_613294 = query.getOrDefault("Action")
  valid_613294 = validateParameter(valid_613294, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_613294 != nil:
    section.add "Action", valid_613294
  var valid_613295 = query.getOrDefault("Operation")
  valid_613295 = validateParameter(valid_613295, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_613295 != nil:
    section.add "Operation", valid_613295
  var valid_613296 = query.getOrDefault("Version")
  valid_613296 = validateParameter(valid_613296, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613296 != nil:
    section.add "Version", valid_613296
  var valid_613297 = query.getOrDefault("SignatureVersion")
  valid_613297 = validateParameter(valid_613297, JString, required = true,
                                 default = nil)
  if valid_613297 != nil:
    section.add "SignatureVersion", valid_613297
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
  var valid_613298 = formData.getOrDefault("ValidateOnly")
  valid_613298 = validateParameter(valid_613298, JBool, required = true, default = nil)
  if valid_613298 != nil:
    section.add "ValidateOnly", valid_613298
  var valid_613299 = formData.getOrDefault("APIVersion")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "APIVersion", valid_613299
  var valid_613300 = formData.getOrDefault("ManifestAddendum")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "ManifestAddendum", valid_613300
  var valid_613301 = formData.getOrDefault("JobType")
  valid_613301 = validateParameter(valid_613301, JString, required = true,
                                 default = newJString("Import"))
  if valid_613301 != nil:
    section.add "JobType", valid_613301
  var valid_613302 = formData.getOrDefault("Manifest")
  valid_613302 = validateParameter(valid_613302, JString, required = true,
                                 default = nil)
  if valid_613302 != nil:
    section.add "Manifest", valid_613302
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613303: Call_PostCreateJob_613287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_613303.validator(path, query, header, formData, body)
  let scheme = call_613303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613303.url(scheme.get, call_613303.host, call_613303.base,
                         call_613303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613303, url, valid)

proc call*(call_613304: Call_PostCreateJob_613287; Signature: string;
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
  var query_613305 = newJObject()
  var formData_613306 = newJObject()
  add(query_613305, "Signature", newJString(Signature))
  add(query_613305, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613305, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613306, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_613306, "APIVersion", newJString(APIVersion))
  add(query_613305, "Timestamp", newJString(Timestamp))
  add(query_613305, "Action", newJString(Action))
  add(formData_613306, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_613305, "Operation", newJString(Operation))
  add(query_613305, "Version", newJString(Version))
  add(formData_613306, "JobType", newJString(JobType))
  add(query_613305, "SignatureVersion", newJString(SignatureVersion))
  add(formData_613306, "Manifest", newJString(Manifest))
  result = call_613304.call(nil, query_613305, nil, formData_613306, nil)

var postCreateJob* = Call_PostCreateJob_613287(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_613288, base: "/", url: url_PostCreateJob_613289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_613268 = ref object of OpenApiRestCall_612642
proc url_GetCreateJob_613270(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateJob_613269(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613271 = query.getOrDefault("Signature")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "Signature", valid_613271
  var valid_613272 = query.getOrDefault("JobType")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = newJString("Import"))
  if valid_613272 != nil:
    section.add "JobType", valid_613272
  var valid_613273 = query.getOrDefault("AWSAccessKeyId")
  valid_613273 = validateParameter(valid_613273, JString, required = true,
                                 default = nil)
  if valid_613273 != nil:
    section.add "AWSAccessKeyId", valid_613273
  var valid_613274 = query.getOrDefault("SignatureMethod")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = nil)
  if valid_613274 != nil:
    section.add "SignatureMethod", valid_613274
  var valid_613275 = query.getOrDefault("Manifest")
  valid_613275 = validateParameter(valid_613275, JString, required = true,
                                 default = nil)
  if valid_613275 != nil:
    section.add "Manifest", valid_613275
  var valid_613276 = query.getOrDefault("ValidateOnly")
  valid_613276 = validateParameter(valid_613276, JBool, required = true, default = nil)
  if valid_613276 != nil:
    section.add "ValidateOnly", valid_613276
  var valid_613277 = query.getOrDefault("Timestamp")
  valid_613277 = validateParameter(valid_613277, JString, required = true,
                                 default = nil)
  if valid_613277 != nil:
    section.add "Timestamp", valid_613277
  var valid_613278 = query.getOrDefault("Action")
  valid_613278 = validateParameter(valid_613278, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_613278 != nil:
    section.add "Action", valid_613278
  var valid_613279 = query.getOrDefault("ManifestAddendum")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "ManifestAddendum", valid_613279
  var valid_613280 = query.getOrDefault("Operation")
  valid_613280 = validateParameter(valid_613280, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_613280 != nil:
    section.add "Operation", valid_613280
  var valid_613281 = query.getOrDefault("APIVersion")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "APIVersion", valid_613281
  var valid_613282 = query.getOrDefault("Version")
  valid_613282 = validateParameter(valid_613282, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613282 != nil:
    section.add "Version", valid_613282
  var valid_613283 = query.getOrDefault("SignatureVersion")
  valid_613283 = validateParameter(valid_613283, JString, required = true,
                                 default = nil)
  if valid_613283 != nil:
    section.add "SignatureVersion", valid_613283
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613284: Call_GetCreateJob_613268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_613284.validator(path, query, header, formData, body)
  let scheme = call_613284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613284.url(scheme.get, call_613284.host, call_613284.base,
                         call_613284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613284, url, valid)

proc call*(call_613285: Call_GetCreateJob_613268; Signature: string;
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
  var query_613286 = newJObject()
  add(query_613286, "Signature", newJString(Signature))
  add(query_613286, "JobType", newJString(JobType))
  add(query_613286, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613286, "SignatureMethod", newJString(SignatureMethod))
  add(query_613286, "Manifest", newJString(Manifest))
  add(query_613286, "ValidateOnly", newJBool(ValidateOnly))
  add(query_613286, "Timestamp", newJString(Timestamp))
  add(query_613286, "Action", newJString(Action))
  add(query_613286, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_613286, "Operation", newJString(Operation))
  add(query_613286, "APIVersion", newJString(APIVersion))
  add(query_613286, "Version", newJString(Version))
  add(query_613286, "SignatureVersion", newJString(SignatureVersion))
  result = call_613285.call(nil, query_613286, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_613268(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_613269, base: "/", url: url_GetCreateJob_613270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_613333 = ref object of OpenApiRestCall_612642
proc url_PostGetShippingLabel_613335(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetShippingLabel_613334(path: JsonNode; query: JsonNode;
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
  var valid_613336 = query.getOrDefault("Signature")
  valid_613336 = validateParameter(valid_613336, JString, required = true,
                                 default = nil)
  if valid_613336 != nil:
    section.add "Signature", valid_613336
  var valid_613337 = query.getOrDefault("AWSAccessKeyId")
  valid_613337 = validateParameter(valid_613337, JString, required = true,
                                 default = nil)
  if valid_613337 != nil:
    section.add "AWSAccessKeyId", valid_613337
  var valid_613338 = query.getOrDefault("SignatureMethod")
  valid_613338 = validateParameter(valid_613338, JString, required = true,
                                 default = nil)
  if valid_613338 != nil:
    section.add "SignatureMethod", valid_613338
  var valid_613339 = query.getOrDefault("Timestamp")
  valid_613339 = validateParameter(valid_613339, JString, required = true,
                                 default = nil)
  if valid_613339 != nil:
    section.add "Timestamp", valid_613339
  var valid_613340 = query.getOrDefault("Action")
  valid_613340 = validateParameter(valid_613340, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_613340 != nil:
    section.add "Action", valid_613340
  var valid_613341 = query.getOrDefault("Operation")
  valid_613341 = validateParameter(valid_613341, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_613341 != nil:
    section.add "Operation", valid_613341
  var valid_613342 = query.getOrDefault("Version")
  valid_613342 = validateParameter(valid_613342, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613342 != nil:
    section.add "Version", valid_613342
  var valid_613343 = query.getOrDefault("SignatureVersion")
  valid_613343 = validateParameter(valid_613343, JString, required = true,
                                 default = nil)
  if valid_613343 != nil:
    section.add "SignatureVersion", valid_613343
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
  var valid_613344 = formData.getOrDefault("street1")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "street1", valid_613344
  var valid_613345 = formData.getOrDefault("stateOrProvince")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "stateOrProvince", valid_613345
  var valid_613346 = formData.getOrDefault("street3")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "street3", valid_613346
  var valid_613347 = formData.getOrDefault("phoneNumber")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "phoneNumber", valid_613347
  var valid_613348 = formData.getOrDefault("postalCode")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "postalCode", valid_613348
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_613349 = formData.getOrDefault("jobIds")
  valid_613349 = validateParameter(valid_613349, JArray, required = true, default = nil)
  if valid_613349 != nil:
    section.add "jobIds", valid_613349
  var valid_613350 = formData.getOrDefault("APIVersion")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "APIVersion", valid_613350
  var valid_613351 = formData.getOrDefault("country")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "country", valid_613351
  var valid_613352 = formData.getOrDefault("city")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "city", valid_613352
  var valid_613353 = formData.getOrDefault("street2")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "street2", valid_613353
  var valid_613354 = formData.getOrDefault("company")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "company", valid_613354
  var valid_613355 = formData.getOrDefault("name")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "name", valid_613355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613356: Call_PostGetShippingLabel_613333; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_613356.validator(path, query, header, formData, body)
  let scheme = call_613356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613356.url(scheme.get, call_613356.host, call_613356.base,
                         call_613356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613356, url, valid)

proc call*(call_613357: Call_PostGetShippingLabel_613333; Signature: string;
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
  var query_613358 = newJObject()
  var formData_613359 = newJObject()
  add(query_613358, "Signature", newJString(Signature))
  add(query_613358, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_613359, "street1", newJString(street1))
  add(query_613358, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613359, "stateOrProvince", newJString(stateOrProvince))
  add(formData_613359, "street3", newJString(street3))
  add(formData_613359, "phoneNumber", newJString(phoneNumber))
  add(formData_613359, "postalCode", newJString(postalCode))
  if jobIds != nil:
    formData_613359.add "jobIds", jobIds
  add(formData_613359, "APIVersion", newJString(APIVersion))
  add(formData_613359, "country", newJString(country))
  add(formData_613359, "city", newJString(city))
  add(formData_613359, "street2", newJString(street2))
  add(query_613358, "Timestamp", newJString(Timestamp))
  add(query_613358, "Action", newJString(Action))
  add(query_613358, "Operation", newJString(Operation))
  add(formData_613359, "company", newJString(company))
  add(query_613358, "Version", newJString(Version))
  add(query_613358, "SignatureVersion", newJString(SignatureVersion))
  add(formData_613359, "name", newJString(name))
  result = call_613357.call(nil, query_613358, nil, formData_613359, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_613333(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_613334, base: "/",
    url: url_PostGetShippingLabel_613335, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_613307 = ref object of OpenApiRestCall_612642
proc url_GetGetShippingLabel_613309(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetShippingLabel_613308(path: JsonNode; query: JsonNode;
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
  var valid_613310 = query.getOrDefault("Signature")
  valid_613310 = validateParameter(valid_613310, JString, required = true,
                                 default = nil)
  if valid_613310 != nil:
    section.add "Signature", valid_613310
  var valid_613311 = query.getOrDefault("name")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "name", valid_613311
  var valid_613312 = query.getOrDefault("street2")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "street2", valid_613312
  var valid_613313 = query.getOrDefault("street3")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "street3", valid_613313
  var valid_613314 = query.getOrDefault("AWSAccessKeyId")
  valid_613314 = validateParameter(valid_613314, JString, required = true,
                                 default = nil)
  if valid_613314 != nil:
    section.add "AWSAccessKeyId", valid_613314
  var valid_613315 = query.getOrDefault("SignatureMethod")
  valid_613315 = validateParameter(valid_613315, JString, required = true,
                                 default = nil)
  if valid_613315 != nil:
    section.add "SignatureMethod", valid_613315
  var valid_613316 = query.getOrDefault("phoneNumber")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "phoneNumber", valid_613316
  var valid_613317 = query.getOrDefault("postalCode")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "postalCode", valid_613317
  var valid_613318 = query.getOrDefault("street1")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "street1", valid_613318
  var valid_613319 = query.getOrDefault("city")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "city", valid_613319
  var valid_613320 = query.getOrDefault("country")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "country", valid_613320
  var valid_613321 = query.getOrDefault("Timestamp")
  valid_613321 = validateParameter(valid_613321, JString, required = true,
                                 default = nil)
  if valid_613321 != nil:
    section.add "Timestamp", valid_613321
  var valid_613322 = query.getOrDefault("Action")
  valid_613322 = validateParameter(valid_613322, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_613322 != nil:
    section.add "Action", valid_613322
  var valid_613323 = query.getOrDefault("jobIds")
  valid_613323 = validateParameter(valid_613323, JArray, required = true, default = nil)
  if valid_613323 != nil:
    section.add "jobIds", valid_613323
  var valid_613324 = query.getOrDefault("Operation")
  valid_613324 = validateParameter(valid_613324, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_613324 != nil:
    section.add "Operation", valid_613324
  var valid_613325 = query.getOrDefault("APIVersion")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "APIVersion", valid_613325
  var valid_613326 = query.getOrDefault("Version")
  valid_613326 = validateParameter(valid_613326, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613326 != nil:
    section.add "Version", valid_613326
  var valid_613327 = query.getOrDefault("stateOrProvince")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "stateOrProvince", valid_613327
  var valid_613328 = query.getOrDefault("SignatureVersion")
  valid_613328 = validateParameter(valid_613328, JString, required = true,
                                 default = nil)
  if valid_613328 != nil:
    section.add "SignatureVersion", valid_613328
  var valid_613329 = query.getOrDefault("company")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "company", valid_613329
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613330: Call_GetGetShippingLabel_613307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_613330.validator(path, query, header, formData, body)
  let scheme = call_613330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613330.url(scheme.get, call_613330.host, call_613330.base,
                         call_613330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613330, url, valid)

proc call*(call_613331: Call_GetGetShippingLabel_613307; Signature: string;
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
  var query_613332 = newJObject()
  add(query_613332, "Signature", newJString(Signature))
  add(query_613332, "name", newJString(name))
  add(query_613332, "street2", newJString(street2))
  add(query_613332, "street3", newJString(street3))
  add(query_613332, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613332, "SignatureMethod", newJString(SignatureMethod))
  add(query_613332, "phoneNumber", newJString(phoneNumber))
  add(query_613332, "postalCode", newJString(postalCode))
  add(query_613332, "street1", newJString(street1))
  add(query_613332, "city", newJString(city))
  add(query_613332, "country", newJString(country))
  add(query_613332, "Timestamp", newJString(Timestamp))
  add(query_613332, "Action", newJString(Action))
  if jobIds != nil:
    query_613332.add "jobIds", jobIds
  add(query_613332, "Operation", newJString(Operation))
  add(query_613332, "APIVersion", newJString(APIVersion))
  add(query_613332, "Version", newJString(Version))
  add(query_613332, "stateOrProvince", newJString(stateOrProvince))
  add(query_613332, "SignatureVersion", newJString(SignatureVersion))
  add(query_613332, "company", newJString(company))
  result = call_613331.call(nil, query_613332, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_613307(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_613308, base: "/",
    url: url_GetGetShippingLabel_613309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_613376 = ref object of OpenApiRestCall_612642
proc url_PostGetStatus_613378(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostGetStatus_613377(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613379 = query.getOrDefault("Signature")
  valid_613379 = validateParameter(valid_613379, JString, required = true,
                                 default = nil)
  if valid_613379 != nil:
    section.add "Signature", valid_613379
  var valid_613380 = query.getOrDefault("AWSAccessKeyId")
  valid_613380 = validateParameter(valid_613380, JString, required = true,
                                 default = nil)
  if valid_613380 != nil:
    section.add "AWSAccessKeyId", valid_613380
  var valid_613381 = query.getOrDefault("SignatureMethod")
  valid_613381 = validateParameter(valid_613381, JString, required = true,
                                 default = nil)
  if valid_613381 != nil:
    section.add "SignatureMethod", valid_613381
  var valid_613382 = query.getOrDefault("Timestamp")
  valid_613382 = validateParameter(valid_613382, JString, required = true,
                                 default = nil)
  if valid_613382 != nil:
    section.add "Timestamp", valid_613382
  var valid_613383 = query.getOrDefault("Action")
  valid_613383 = validateParameter(valid_613383, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_613383 != nil:
    section.add "Action", valid_613383
  var valid_613384 = query.getOrDefault("Operation")
  valid_613384 = validateParameter(valid_613384, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_613384 != nil:
    section.add "Operation", valid_613384
  var valid_613385 = query.getOrDefault("Version")
  valid_613385 = validateParameter(valid_613385, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613385 != nil:
    section.add "Version", valid_613385
  var valid_613386 = query.getOrDefault("SignatureVersion")
  valid_613386 = validateParameter(valid_613386, JString, required = true,
                                 default = nil)
  if valid_613386 != nil:
    section.add "SignatureVersion", valid_613386
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_613387 = formData.getOrDefault("APIVersion")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "APIVersion", valid_613387
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_613388 = formData.getOrDefault("JobId")
  valid_613388 = validateParameter(valid_613388, JString, required = true,
                                 default = nil)
  if valid_613388 != nil:
    section.add "JobId", valid_613388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613389: Call_PostGetStatus_613376; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_613389.validator(path, query, header, formData, body)
  let scheme = call_613389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613389.url(scheme.get, call_613389.host, call_613389.base,
                         call_613389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613389, url, valid)

proc call*(call_613390: Call_PostGetStatus_613376; Signature: string;
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
  var query_613391 = newJObject()
  var formData_613392 = newJObject()
  add(query_613391, "Signature", newJString(Signature))
  add(query_613391, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613391, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613392, "APIVersion", newJString(APIVersion))
  add(query_613391, "Timestamp", newJString(Timestamp))
  add(query_613391, "Action", newJString(Action))
  add(query_613391, "Operation", newJString(Operation))
  add(formData_613392, "JobId", newJString(JobId))
  add(query_613391, "Version", newJString(Version))
  add(query_613391, "SignatureVersion", newJString(SignatureVersion))
  result = call_613390.call(nil, query_613391, nil, formData_613392, nil)

var postGetStatus* = Call_PostGetStatus_613376(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_613377, base: "/", url: url_PostGetStatus_613378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_613360 = ref object of OpenApiRestCall_612642
proc url_GetGetStatus_613362(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGetStatus_613361(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613363 = query.getOrDefault("Signature")
  valid_613363 = validateParameter(valid_613363, JString, required = true,
                                 default = nil)
  if valid_613363 != nil:
    section.add "Signature", valid_613363
  var valid_613364 = query.getOrDefault("AWSAccessKeyId")
  valid_613364 = validateParameter(valid_613364, JString, required = true,
                                 default = nil)
  if valid_613364 != nil:
    section.add "AWSAccessKeyId", valid_613364
  var valid_613365 = query.getOrDefault("SignatureMethod")
  valid_613365 = validateParameter(valid_613365, JString, required = true,
                                 default = nil)
  if valid_613365 != nil:
    section.add "SignatureMethod", valid_613365
  var valid_613366 = query.getOrDefault("Timestamp")
  valid_613366 = validateParameter(valid_613366, JString, required = true,
                                 default = nil)
  if valid_613366 != nil:
    section.add "Timestamp", valid_613366
  var valid_613367 = query.getOrDefault("Action")
  valid_613367 = validateParameter(valid_613367, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_613367 != nil:
    section.add "Action", valid_613367
  var valid_613368 = query.getOrDefault("Operation")
  valid_613368 = validateParameter(valid_613368, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_613368 != nil:
    section.add "Operation", valid_613368
  var valid_613369 = query.getOrDefault("APIVersion")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "APIVersion", valid_613369
  var valid_613370 = query.getOrDefault("Version")
  valid_613370 = validateParameter(valid_613370, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613370 != nil:
    section.add "Version", valid_613370
  var valid_613371 = query.getOrDefault("JobId")
  valid_613371 = validateParameter(valid_613371, JString, required = true,
                                 default = nil)
  if valid_613371 != nil:
    section.add "JobId", valid_613371
  var valid_613372 = query.getOrDefault("SignatureVersion")
  valid_613372 = validateParameter(valid_613372, JString, required = true,
                                 default = nil)
  if valid_613372 != nil:
    section.add "SignatureVersion", valid_613372
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613373: Call_GetGetStatus_613360; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_613373.validator(path, query, header, formData, body)
  let scheme = call_613373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613373.url(scheme.get, call_613373.host, call_613373.base,
                         call_613373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613373, url, valid)

proc call*(call_613374: Call_GetGetStatus_613360; Signature: string;
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
  var query_613375 = newJObject()
  add(query_613375, "Signature", newJString(Signature))
  add(query_613375, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613375, "SignatureMethod", newJString(SignatureMethod))
  add(query_613375, "Timestamp", newJString(Timestamp))
  add(query_613375, "Action", newJString(Action))
  add(query_613375, "Operation", newJString(Operation))
  add(query_613375, "APIVersion", newJString(APIVersion))
  add(query_613375, "Version", newJString(Version))
  add(query_613375, "JobId", newJString(JobId))
  add(query_613375, "SignatureVersion", newJString(SignatureVersion))
  result = call_613374.call(nil, query_613375, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_613360(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_613361, base: "/", url: url_GetGetStatus_613362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_613410 = ref object of OpenApiRestCall_612642
proc url_PostListJobs_613412(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListJobs_613411(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613413 = query.getOrDefault("Signature")
  valid_613413 = validateParameter(valid_613413, JString, required = true,
                                 default = nil)
  if valid_613413 != nil:
    section.add "Signature", valid_613413
  var valid_613414 = query.getOrDefault("AWSAccessKeyId")
  valid_613414 = validateParameter(valid_613414, JString, required = true,
                                 default = nil)
  if valid_613414 != nil:
    section.add "AWSAccessKeyId", valid_613414
  var valid_613415 = query.getOrDefault("SignatureMethod")
  valid_613415 = validateParameter(valid_613415, JString, required = true,
                                 default = nil)
  if valid_613415 != nil:
    section.add "SignatureMethod", valid_613415
  var valid_613416 = query.getOrDefault("Timestamp")
  valid_613416 = validateParameter(valid_613416, JString, required = true,
                                 default = nil)
  if valid_613416 != nil:
    section.add "Timestamp", valid_613416
  var valid_613417 = query.getOrDefault("Action")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_613417 != nil:
    section.add "Action", valid_613417
  var valid_613418 = query.getOrDefault("Operation")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_613418 != nil:
    section.add "Operation", valid_613418
  var valid_613419 = query.getOrDefault("Version")
  valid_613419 = validateParameter(valid_613419, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613419 != nil:
    section.add "Version", valid_613419
  var valid_613420 = query.getOrDefault("SignatureVersion")
  valid_613420 = validateParameter(valid_613420, JString, required = true,
                                 default = nil)
  if valid_613420 != nil:
    section.add "SignatureVersion", valid_613420
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
  var valid_613421 = formData.getOrDefault("MaxJobs")
  valid_613421 = validateParameter(valid_613421, JInt, required = false, default = nil)
  if valid_613421 != nil:
    section.add "MaxJobs", valid_613421
  var valid_613422 = formData.getOrDefault("Marker")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "Marker", valid_613422
  var valid_613423 = formData.getOrDefault("APIVersion")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "APIVersion", valid_613423
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613424: Call_PostListJobs_613410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_613424.validator(path, query, header, formData, body)
  let scheme = call_613424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613424.url(scheme.get, call_613424.host, call_613424.base,
                         call_613424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613424, url, valid)

proc call*(call_613425: Call_PostListJobs_613410; Signature: string;
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
  var query_613426 = newJObject()
  var formData_613427 = newJObject()
  add(query_613426, "Signature", newJString(Signature))
  add(formData_613427, "MaxJobs", newJInt(MaxJobs))
  add(query_613426, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613426, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613427, "Marker", newJString(Marker))
  add(formData_613427, "APIVersion", newJString(APIVersion))
  add(query_613426, "Timestamp", newJString(Timestamp))
  add(query_613426, "Action", newJString(Action))
  add(query_613426, "Operation", newJString(Operation))
  add(query_613426, "Version", newJString(Version))
  add(query_613426, "SignatureVersion", newJString(SignatureVersion))
  result = call_613425.call(nil, query_613426, nil, formData_613427, nil)

var postListJobs* = Call_PostListJobs_613410(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_613411, base: "/", url: url_PostListJobs_613412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_613393 = ref object of OpenApiRestCall_612642
proc url_GetListJobs_613395(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListJobs_613394(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613396 = query.getOrDefault("MaxJobs")
  valid_613396 = validateParameter(valid_613396, JInt, required = false, default = nil)
  if valid_613396 != nil:
    section.add "MaxJobs", valid_613396
  var valid_613397 = query.getOrDefault("Marker")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "Marker", valid_613397
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_613398 = query.getOrDefault("Signature")
  valid_613398 = validateParameter(valid_613398, JString, required = true,
                                 default = nil)
  if valid_613398 != nil:
    section.add "Signature", valid_613398
  var valid_613399 = query.getOrDefault("AWSAccessKeyId")
  valid_613399 = validateParameter(valid_613399, JString, required = true,
                                 default = nil)
  if valid_613399 != nil:
    section.add "AWSAccessKeyId", valid_613399
  var valid_613400 = query.getOrDefault("SignatureMethod")
  valid_613400 = validateParameter(valid_613400, JString, required = true,
                                 default = nil)
  if valid_613400 != nil:
    section.add "SignatureMethod", valid_613400
  var valid_613401 = query.getOrDefault("Timestamp")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = nil)
  if valid_613401 != nil:
    section.add "Timestamp", valid_613401
  var valid_613402 = query.getOrDefault("Action")
  valid_613402 = validateParameter(valid_613402, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_613402 != nil:
    section.add "Action", valid_613402
  var valid_613403 = query.getOrDefault("Operation")
  valid_613403 = validateParameter(valid_613403, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_613403 != nil:
    section.add "Operation", valid_613403
  var valid_613404 = query.getOrDefault("APIVersion")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "APIVersion", valid_613404
  var valid_613405 = query.getOrDefault("Version")
  valid_613405 = validateParameter(valid_613405, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613405 != nil:
    section.add "Version", valid_613405
  var valid_613406 = query.getOrDefault("SignatureVersion")
  valid_613406 = validateParameter(valid_613406, JString, required = true,
                                 default = nil)
  if valid_613406 != nil:
    section.add "SignatureVersion", valid_613406
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613407: Call_GetListJobs_613393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_613407.validator(path, query, header, formData, body)
  let scheme = call_613407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613407.url(scheme.get, call_613407.host, call_613407.base,
                         call_613407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613407, url, valid)

proc call*(call_613408: Call_GetListJobs_613393; Signature: string;
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
  var query_613409 = newJObject()
  add(query_613409, "MaxJobs", newJInt(MaxJobs))
  add(query_613409, "Marker", newJString(Marker))
  add(query_613409, "Signature", newJString(Signature))
  add(query_613409, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613409, "SignatureMethod", newJString(SignatureMethod))
  add(query_613409, "Timestamp", newJString(Timestamp))
  add(query_613409, "Action", newJString(Action))
  add(query_613409, "Operation", newJString(Operation))
  add(query_613409, "APIVersion", newJString(APIVersion))
  add(query_613409, "Version", newJString(Version))
  add(query_613409, "SignatureVersion", newJString(SignatureVersion))
  result = call_613408.call(nil, query_613409, nil, nil, nil)

var getListJobs* = Call_GetListJobs_613393(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_613394,
                                        base: "/", url: url_GetListJobs_613395,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_613447 = ref object of OpenApiRestCall_612642
proc url_PostUpdateJob_613449(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateJob_613448(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613450 = query.getOrDefault("Signature")
  valid_613450 = validateParameter(valid_613450, JString, required = true,
                                 default = nil)
  if valid_613450 != nil:
    section.add "Signature", valid_613450
  var valid_613451 = query.getOrDefault("AWSAccessKeyId")
  valid_613451 = validateParameter(valid_613451, JString, required = true,
                                 default = nil)
  if valid_613451 != nil:
    section.add "AWSAccessKeyId", valid_613451
  var valid_613452 = query.getOrDefault("SignatureMethod")
  valid_613452 = validateParameter(valid_613452, JString, required = true,
                                 default = nil)
  if valid_613452 != nil:
    section.add "SignatureMethod", valid_613452
  var valid_613453 = query.getOrDefault("Timestamp")
  valid_613453 = validateParameter(valid_613453, JString, required = true,
                                 default = nil)
  if valid_613453 != nil:
    section.add "Timestamp", valid_613453
  var valid_613454 = query.getOrDefault("Action")
  valid_613454 = validateParameter(valid_613454, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_613454 != nil:
    section.add "Action", valid_613454
  var valid_613455 = query.getOrDefault("Operation")
  valid_613455 = validateParameter(valid_613455, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_613455 != nil:
    section.add "Operation", valid_613455
  var valid_613456 = query.getOrDefault("Version")
  valid_613456 = validateParameter(valid_613456, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613456 != nil:
    section.add "Version", valid_613456
  var valid_613457 = query.getOrDefault("SignatureVersion")
  valid_613457 = validateParameter(valid_613457, JString, required = true,
                                 default = nil)
  if valid_613457 != nil:
    section.add "SignatureVersion", valid_613457
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
  var valid_613458 = formData.getOrDefault("ValidateOnly")
  valid_613458 = validateParameter(valid_613458, JBool, required = true, default = nil)
  if valid_613458 != nil:
    section.add "ValidateOnly", valid_613458
  var valid_613459 = formData.getOrDefault("APIVersion")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "APIVersion", valid_613459
  var valid_613460 = formData.getOrDefault("JobId")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "JobId", valid_613460
  var valid_613461 = formData.getOrDefault("JobType")
  valid_613461 = validateParameter(valid_613461, JString, required = true,
                                 default = newJString("Import"))
  if valid_613461 != nil:
    section.add "JobType", valid_613461
  var valid_613462 = formData.getOrDefault("Manifest")
  valid_613462 = validateParameter(valid_613462, JString, required = true,
                                 default = nil)
  if valid_613462 != nil:
    section.add "Manifest", valid_613462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613463: Call_PostUpdateJob_613447; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_613463.validator(path, query, header, formData, body)
  let scheme = call_613463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613463.url(scheme.get, call_613463.host, call_613463.base,
                         call_613463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613463, url, valid)

proc call*(call_613464: Call_PostUpdateJob_613447; Signature: string;
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
  var query_613465 = newJObject()
  var formData_613466 = newJObject()
  add(query_613465, "Signature", newJString(Signature))
  add(query_613465, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613465, "SignatureMethod", newJString(SignatureMethod))
  add(formData_613466, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_613466, "APIVersion", newJString(APIVersion))
  add(query_613465, "Timestamp", newJString(Timestamp))
  add(query_613465, "Action", newJString(Action))
  add(query_613465, "Operation", newJString(Operation))
  add(formData_613466, "JobId", newJString(JobId))
  add(query_613465, "Version", newJString(Version))
  add(formData_613466, "JobType", newJString(JobType))
  add(query_613465, "SignatureVersion", newJString(SignatureVersion))
  add(formData_613466, "Manifest", newJString(Manifest))
  result = call_613464.call(nil, query_613465, nil, formData_613466, nil)

var postUpdateJob* = Call_PostUpdateJob_613447(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_613448, base: "/", url: url_PostUpdateJob_613449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_613428 = ref object of OpenApiRestCall_612642
proc url_GetUpdateJob_613430(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateJob_613429(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613431 = query.getOrDefault("Signature")
  valid_613431 = validateParameter(valid_613431, JString, required = true,
                                 default = nil)
  if valid_613431 != nil:
    section.add "Signature", valid_613431
  var valid_613432 = query.getOrDefault("JobType")
  valid_613432 = validateParameter(valid_613432, JString, required = true,
                                 default = newJString("Import"))
  if valid_613432 != nil:
    section.add "JobType", valid_613432
  var valid_613433 = query.getOrDefault("AWSAccessKeyId")
  valid_613433 = validateParameter(valid_613433, JString, required = true,
                                 default = nil)
  if valid_613433 != nil:
    section.add "AWSAccessKeyId", valid_613433
  var valid_613434 = query.getOrDefault("SignatureMethod")
  valid_613434 = validateParameter(valid_613434, JString, required = true,
                                 default = nil)
  if valid_613434 != nil:
    section.add "SignatureMethod", valid_613434
  var valid_613435 = query.getOrDefault("Manifest")
  valid_613435 = validateParameter(valid_613435, JString, required = true,
                                 default = nil)
  if valid_613435 != nil:
    section.add "Manifest", valid_613435
  var valid_613436 = query.getOrDefault("ValidateOnly")
  valid_613436 = validateParameter(valid_613436, JBool, required = true, default = nil)
  if valid_613436 != nil:
    section.add "ValidateOnly", valid_613436
  var valid_613437 = query.getOrDefault("Timestamp")
  valid_613437 = validateParameter(valid_613437, JString, required = true,
                                 default = nil)
  if valid_613437 != nil:
    section.add "Timestamp", valid_613437
  var valid_613438 = query.getOrDefault("Action")
  valid_613438 = validateParameter(valid_613438, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_613438 != nil:
    section.add "Action", valid_613438
  var valid_613439 = query.getOrDefault("Operation")
  valid_613439 = validateParameter(valid_613439, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_613439 != nil:
    section.add "Operation", valid_613439
  var valid_613440 = query.getOrDefault("APIVersion")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "APIVersion", valid_613440
  var valid_613441 = query.getOrDefault("Version")
  valid_613441 = validateParameter(valid_613441, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_613441 != nil:
    section.add "Version", valid_613441
  var valid_613442 = query.getOrDefault("JobId")
  valid_613442 = validateParameter(valid_613442, JString, required = true,
                                 default = nil)
  if valid_613442 != nil:
    section.add "JobId", valid_613442
  var valid_613443 = query.getOrDefault("SignatureVersion")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = nil)
  if valid_613443 != nil:
    section.add "SignatureVersion", valid_613443
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613444: Call_GetUpdateJob_613428; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_613444.validator(path, query, header, formData, body)
  let scheme = call_613444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613444.url(scheme.get, call_613444.host, call_613444.base,
                         call_613444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613444, url, valid)

proc call*(call_613445: Call_GetUpdateJob_613428; Signature: string;
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
  var query_613446 = newJObject()
  add(query_613446, "Signature", newJString(Signature))
  add(query_613446, "JobType", newJString(JobType))
  add(query_613446, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_613446, "SignatureMethod", newJString(SignatureMethod))
  add(query_613446, "Manifest", newJString(Manifest))
  add(query_613446, "ValidateOnly", newJBool(ValidateOnly))
  add(query_613446, "Timestamp", newJString(Timestamp))
  add(query_613446, "Action", newJString(Action))
  add(query_613446, "Operation", newJString(Operation))
  add(query_613446, "APIVersion", newJString(APIVersion))
  add(query_613446, "Version", newJString(Version))
  add(query_613446, "JobId", newJString(JobId))
  add(query_613446, "SignatureVersion", newJString(SignatureVersion))
  result = call_613445.call(nil, query_613446, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_613428(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_613429, base: "/", url: url_GetUpdateJob_613430,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
