
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

  OpenApiRestCall_605573 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605573](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605573): Option[Scheme] {.used.} =
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
  Call_PostCancelJob_606182 = ref object of OpenApiRestCall_605573
proc url_PostCancelJob_606184(protocol: Scheme; host: string; base: string;
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

proc validate_PostCancelJob_606183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606185 = query.getOrDefault("Signature")
  valid_606185 = validateParameter(valid_606185, JString, required = true,
                                 default = nil)
  if valid_606185 != nil:
    section.add "Signature", valid_606185
  var valid_606186 = query.getOrDefault("AWSAccessKeyId")
  valid_606186 = validateParameter(valid_606186, JString, required = true,
                                 default = nil)
  if valid_606186 != nil:
    section.add "AWSAccessKeyId", valid_606186
  var valid_606187 = query.getOrDefault("SignatureMethod")
  valid_606187 = validateParameter(valid_606187, JString, required = true,
                                 default = nil)
  if valid_606187 != nil:
    section.add "SignatureMethod", valid_606187
  var valid_606188 = query.getOrDefault("Timestamp")
  valid_606188 = validateParameter(valid_606188, JString, required = true,
                                 default = nil)
  if valid_606188 != nil:
    section.add "Timestamp", valid_606188
  var valid_606189 = query.getOrDefault("Action")
  valid_606189 = validateParameter(valid_606189, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_606189 != nil:
    section.add "Action", valid_606189
  var valid_606190 = query.getOrDefault("Operation")
  valid_606190 = validateParameter(valid_606190, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_606190 != nil:
    section.add "Operation", valid_606190
  var valid_606191 = query.getOrDefault("Version")
  valid_606191 = validateParameter(valid_606191, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606191 != nil:
    section.add "Version", valid_606191
  var valid_606192 = query.getOrDefault("SignatureVersion")
  valid_606192 = validateParameter(valid_606192, JString, required = true,
                                 default = nil)
  if valid_606192 != nil:
    section.add "SignatureVersion", valid_606192
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_606193 = formData.getOrDefault("APIVersion")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "APIVersion", valid_606193
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_606194 = formData.getOrDefault("JobId")
  valid_606194 = validateParameter(valid_606194, JString, required = true,
                                 default = nil)
  if valid_606194 != nil:
    section.add "JobId", valid_606194
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606195: Call_PostCancelJob_606182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_606195.validator(path, query, header, formData, body)
  let scheme = call_606195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606195.url(scheme.get, call_606195.host, call_606195.base,
                         call_606195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606195, url, valid)

proc call*(call_606196: Call_PostCancelJob_606182; Signature: string;
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
  var query_606197 = newJObject()
  var formData_606198 = newJObject()
  add(query_606197, "Signature", newJString(Signature))
  add(query_606197, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606197, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606198, "APIVersion", newJString(APIVersion))
  add(query_606197, "Timestamp", newJString(Timestamp))
  add(query_606197, "Action", newJString(Action))
  add(query_606197, "Operation", newJString(Operation))
  add(formData_606198, "JobId", newJString(JobId))
  add(query_606197, "Version", newJString(Version))
  add(query_606197, "SignatureVersion", newJString(SignatureVersion))
  result = call_606196.call(nil, query_606197, nil, formData_606198, nil)

var postCancelJob* = Call_PostCancelJob_606182(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_606183, base: "/", url: url_PostCancelJob_606184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_605911 = ref object of OpenApiRestCall_605573
proc url_GetCancelJob_605913(protocol: Scheme; host: string; base: string;
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

proc validate_GetCancelJob_605912(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606025 = query.getOrDefault("Signature")
  valid_606025 = validateParameter(valid_606025, JString, required = true,
                                 default = nil)
  if valid_606025 != nil:
    section.add "Signature", valid_606025
  var valid_606026 = query.getOrDefault("AWSAccessKeyId")
  valid_606026 = validateParameter(valid_606026, JString, required = true,
                                 default = nil)
  if valid_606026 != nil:
    section.add "AWSAccessKeyId", valid_606026
  var valid_606027 = query.getOrDefault("SignatureMethod")
  valid_606027 = validateParameter(valid_606027, JString, required = true,
                                 default = nil)
  if valid_606027 != nil:
    section.add "SignatureMethod", valid_606027
  var valid_606028 = query.getOrDefault("Timestamp")
  valid_606028 = validateParameter(valid_606028, JString, required = true,
                                 default = nil)
  if valid_606028 != nil:
    section.add "Timestamp", valid_606028
  var valid_606042 = query.getOrDefault("Action")
  valid_606042 = validateParameter(valid_606042, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_606042 != nil:
    section.add "Action", valid_606042
  var valid_606043 = query.getOrDefault("Operation")
  valid_606043 = validateParameter(valid_606043, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_606043 != nil:
    section.add "Operation", valid_606043
  var valid_606044 = query.getOrDefault("APIVersion")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "APIVersion", valid_606044
  var valid_606045 = query.getOrDefault("Version")
  valid_606045 = validateParameter(valid_606045, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606045 != nil:
    section.add "Version", valid_606045
  var valid_606046 = query.getOrDefault("JobId")
  valid_606046 = validateParameter(valid_606046, JString, required = true,
                                 default = nil)
  if valid_606046 != nil:
    section.add "JobId", valid_606046
  var valid_606047 = query.getOrDefault("SignatureVersion")
  valid_606047 = validateParameter(valid_606047, JString, required = true,
                                 default = nil)
  if valid_606047 != nil:
    section.add "SignatureVersion", valid_606047
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606070: Call_GetCancelJob_605911; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_606070.validator(path, query, header, formData, body)
  let scheme = call_606070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606070.url(scheme.get, call_606070.host, call_606070.base,
                         call_606070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606070, url, valid)

proc call*(call_606141: Call_GetCancelJob_605911; Signature: string;
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
  var query_606142 = newJObject()
  add(query_606142, "Signature", newJString(Signature))
  add(query_606142, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606142, "SignatureMethod", newJString(SignatureMethod))
  add(query_606142, "Timestamp", newJString(Timestamp))
  add(query_606142, "Action", newJString(Action))
  add(query_606142, "Operation", newJString(Operation))
  add(query_606142, "APIVersion", newJString(APIVersion))
  add(query_606142, "Version", newJString(Version))
  add(query_606142, "JobId", newJString(JobId))
  add(query_606142, "SignatureVersion", newJString(SignatureVersion))
  result = call_606141.call(nil, query_606142, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_605911(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_605912, base: "/", url: url_GetCancelJob_605913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_606218 = ref object of OpenApiRestCall_605573
proc url_PostCreateJob_606220(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateJob_606219(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606221 = query.getOrDefault("Signature")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "Signature", valid_606221
  var valid_606222 = query.getOrDefault("AWSAccessKeyId")
  valid_606222 = validateParameter(valid_606222, JString, required = true,
                                 default = nil)
  if valid_606222 != nil:
    section.add "AWSAccessKeyId", valid_606222
  var valid_606223 = query.getOrDefault("SignatureMethod")
  valid_606223 = validateParameter(valid_606223, JString, required = true,
                                 default = nil)
  if valid_606223 != nil:
    section.add "SignatureMethod", valid_606223
  var valid_606224 = query.getOrDefault("Timestamp")
  valid_606224 = validateParameter(valid_606224, JString, required = true,
                                 default = nil)
  if valid_606224 != nil:
    section.add "Timestamp", valid_606224
  var valid_606225 = query.getOrDefault("Action")
  valid_606225 = validateParameter(valid_606225, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_606225 != nil:
    section.add "Action", valid_606225
  var valid_606226 = query.getOrDefault("Operation")
  valid_606226 = validateParameter(valid_606226, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_606226 != nil:
    section.add "Operation", valid_606226
  var valid_606227 = query.getOrDefault("Version")
  valid_606227 = validateParameter(valid_606227, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606227 != nil:
    section.add "Version", valid_606227
  var valid_606228 = query.getOrDefault("SignatureVersion")
  valid_606228 = validateParameter(valid_606228, JString, required = true,
                                 default = nil)
  if valid_606228 != nil:
    section.add "SignatureVersion", valid_606228
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
  var valid_606229 = formData.getOrDefault("ValidateOnly")
  valid_606229 = validateParameter(valid_606229, JBool, required = true, default = nil)
  if valid_606229 != nil:
    section.add "ValidateOnly", valid_606229
  var valid_606230 = formData.getOrDefault("APIVersion")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "APIVersion", valid_606230
  var valid_606231 = formData.getOrDefault("ManifestAddendum")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "ManifestAddendum", valid_606231
  var valid_606232 = formData.getOrDefault("JobType")
  valid_606232 = validateParameter(valid_606232, JString, required = true,
                                 default = newJString("Import"))
  if valid_606232 != nil:
    section.add "JobType", valid_606232
  var valid_606233 = formData.getOrDefault("Manifest")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "Manifest", valid_606233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606234: Call_PostCreateJob_606218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_606234.validator(path, query, header, formData, body)
  let scheme = call_606234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606234.url(scheme.get, call_606234.host, call_606234.base,
                         call_606234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606234, url, valid)

proc call*(call_606235: Call_PostCreateJob_606218; Signature: string;
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
  var query_606236 = newJObject()
  var formData_606237 = newJObject()
  add(query_606236, "Signature", newJString(Signature))
  add(query_606236, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606236, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606237, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_606237, "APIVersion", newJString(APIVersion))
  add(query_606236, "Timestamp", newJString(Timestamp))
  add(query_606236, "Action", newJString(Action))
  add(formData_606237, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_606236, "Operation", newJString(Operation))
  add(query_606236, "Version", newJString(Version))
  add(formData_606237, "JobType", newJString(JobType))
  add(query_606236, "SignatureVersion", newJString(SignatureVersion))
  add(formData_606237, "Manifest", newJString(Manifest))
  result = call_606235.call(nil, query_606236, nil, formData_606237, nil)

var postCreateJob* = Call_PostCreateJob_606218(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_606219, base: "/", url: url_PostCreateJob_606220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_606199 = ref object of OpenApiRestCall_605573
proc url_GetCreateJob_606201(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateJob_606200(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606202 = query.getOrDefault("Signature")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "Signature", valid_606202
  var valid_606203 = query.getOrDefault("JobType")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = newJString("Import"))
  if valid_606203 != nil:
    section.add "JobType", valid_606203
  var valid_606204 = query.getOrDefault("AWSAccessKeyId")
  valid_606204 = validateParameter(valid_606204, JString, required = true,
                                 default = nil)
  if valid_606204 != nil:
    section.add "AWSAccessKeyId", valid_606204
  var valid_606205 = query.getOrDefault("SignatureMethod")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "SignatureMethod", valid_606205
  var valid_606206 = query.getOrDefault("Manifest")
  valid_606206 = validateParameter(valid_606206, JString, required = true,
                                 default = nil)
  if valid_606206 != nil:
    section.add "Manifest", valid_606206
  var valid_606207 = query.getOrDefault("ValidateOnly")
  valid_606207 = validateParameter(valid_606207, JBool, required = true, default = nil)
  if valid_606207 != nil:
    section.add "ValidateOnly", valid_606207
  var valid_606208 = query.getOrDefault("Timestamp")
  valid_606208 = validateParameter(valid_606208, JString, required = true,
                                 default = nil)
  if valid_606208 != nil:
    section.add "Timestamp", valid_606208
  var valid_606209 = query.getOrDefault("Action")
  valid_606209 = validateParameter(valid_606209, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_606209 != nil:
    section.add "Action", valid_606209
  var valid_606210 = query.getOrDefault("ManifestAddendum")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "ManifestAddendum", valid_606210
  var valid_606211 = query.getOrDefault("Operation")
  valid_606211 = validateParameter(valid_606211, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_606211 != nil:
    section.add "Operation", valid_606211
  var valid_606212 = query.getOrDefault("APIVersion")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "APIVersion", valid_606212
  var valid_606213 = query.getOrDefault("Version")
  valid_606213 = validateParameter(valid_606213, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606213 != nil:
    section.add "Version", valid_606213
  var valid_606214 = query.getOrDefault("SignatureVersion")
  valid_606214 = validateParameter(valid_606214, JString, required = true,
                                 default = nil)
  if valid_606214 != nil:
    section.add "SignatureVersion", valid_606214
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606215: Call_GetCreateJob_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_606215.validator(path, query, header, formData, body)
  let scheme = call_606215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606215.url(scheme.get, call_606215.host, call_606215.base,
                         call_606215.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606215, url, valid)

proc call*(call_606216: Call_GetCreateJob_606199; Signature: string;
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
  var query_606217 = newJObject()
  add(query_606217, "Signature", newJString(Signature))
  add(query_606217, "JobType", newJString(JobType))
  add(query_606217, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606217, "SignatureMethod", newJString(SignatureMethod))
  add(query_606217, "Manifest", newJString(Manifest))
  add(query_606217, "ValidateOnly", newJBool(ValidateOnly))
  add(query_606217, "Timestamp", newJString(Timestamp))
  add(query_606217, "Action", newJString(Action))
  add(query_606217, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_606217, "Operation", newJString(Operation))
  add(query_606217, "APIVersion", newJString(APIVersion))
  add(query_606217, "Version", newJString(Version))
  add(query_606217, "SignatureVersion", newJString(SignatureVersion))
  result = call_606216.call(nil, query_606217, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_606199(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_606200, base: "/", url: url_GetCreateJob_606201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_606264 = ref object of OpenApiRestCall_605573
proc url_PostGetShippingLabel_606266(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetShippingLabel_606265(path: JsonNode; query: JsonNode;
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
  var valid_606267 = query.getOrDefault("Signature")
  valid_606267 = validateParameter(valid_606267, JString, required = true,
                                 default = nil)
  if valid_606267 != nil:
    section.add "Signature", valid_606267
  var valid_606268 = query.getOrDefault("AWSAccessKeyId")
  valid_606268 = validateParameter(valid_606268, JString, required = true,
                                 default = nil)
  if valid_606268 != nil:
    section.add "AWSAccessKeyId", valid_606268
  var valid_606269 = query.getOrDefault("SignatureMethod")
  valid_606269 = validateParameter(valid_606269, JString, required = true,
                                 default = nil)
  if valid_606269 != nil:
    section.add "SignatureMethod", valid_606269
  var valid_606270 = query.getOrDefault("Timestamp")
  valid_606270 = validateParameter(valid_606270, JString, required = true,
                                 default = nil)
  if valid_606270 != nil:
    section.add "Timestamp", valid_606270
  var valid_606271 = query.getOrDefault("Action")
  valid_606271 = validateParameter(valid_606271, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_606271 != nil:
    section.add "Action", valid_606271
  var valid_606272 = query.getOrDefault("Operation")
  valid_606272 = validateParameter(valid_606272, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_606272 != nil:
    section.add "Operation", valid_606272
  var valid_606273 = query.getOrDefault("Version")
  valid_606273 = validateParameter(valid_606273, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606273 != nil:
    section.add "Version", valid_606273
  var valid_606274 = query.getOrDefault("SignatureVersion")
  valid_606274 = validateParameter(valid_606274, JString, required = true,
                                 default = nil)
  if valid_606274 != nil:
    section.add "SignatureVersion", valid_606274
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
  var valid_606275 = formData.getOrDefault("street1")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "street1", valid_606275
  var valid_606276 = formData.getOrDefault("stateOrProvince")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "stateOrProvince", valid_606276
  var valid_606277 = formData.getOrDefault("street3")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "street3", valid_606277
  var valid_606278 = formData.getOrDefault("phoneNumber")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "phoneNumber", valid_606278
  var valid_606279 = formData.getOrDefault("postalCode")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "postalCode", valid_606279
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_606280 = formData.getOrDefault("jobIds")
  valid_606280 = validateParameter(valid_606280, JArray, required = true, default = nil)
  if valid_606280 != nil:
    section.add "jobIds", valid_606280
  var valid_606281 = formData.getOrDefault("APIVersion")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "APIVersion", valid_606281
  var valid_606282 = formData.getOrDefault("country")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "country", valid_606282
  var valid_606283 = formData.getOrDefault("city")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "city", valid_606283
  var valid_606284 = formData.getOrDefault("street2")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "street2", valid_606284
  var valid_606285 = formData.getOrDefault("company")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "company", valid_606285
  var valid_606286 = formData.getOrDefault("name")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "name", valid_606286
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606287: Call_PostGetShippingLabel_606264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_606287.validator(path, query, header, formData, body)
  let scheme = call_606287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606287.url(scheme.get, call_606287.host, call_606287.base,
                         call_606287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606287, url, valid)

proc call*(call_606288: Call_PostGetShippingLabel_606264; Signature: string;
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
  var query_606289 = newJObject()
  var formData_606290 = newJObject()
  add(query_606289, "Signature", newJString(Signature))
  add(query_606289, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_606290, "street1", newJString(street1))
  add(query_606289, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606290, "stateOrProvince", newJString(stateOrProvince))
  add(formData_606290, "street3", newJString(street3))
  add(formData_606290, "phoneNumber", newJString(phoneNumber))
  add(formData_606290, "postalCode", newJString(postalCode))
  if jobIds != nil:
    formData_606290.add "jobIds", jobIds
  add(formData_606290, "APIVersion", newJString(APIVersion))
  add(formData_606290, "country", newJString(country))
  add(formData_606290, "city", newJString(city))
  add(formData_606290, "street2", newJString(street2))
  add(query_606289, "Timestamp", newJString(Timestamp))
  add(query_606289, "Action", newJString(Action))
  add(query_606289, "Operation", newJString(Operation))
  add(formData_606290, "company", newJString(company))
  add(query_606289, "Version", newJString(Version))
  add(query_606289, "SignatureVersion", newJString(SignatureVersion))
  add(formData_606290, "name", newJString(name))
  result = call_606288.call(nil, query_606289, nil, formData_606290, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_606264(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_606265, base: "/",
    url: url_PostGetShippingLabel_606266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_606238 = ref object of OpenApiRestCall_605573
proc url_GetGetShippingLabel_606240(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetShippingLabel_606239(path: JsonNode; query: JsonNode;
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
  var valid_606241 = query.getOrDefault("Signature")
  valid_606241 = validateParameter(valid_606241, JString, required = true,
                                 default = nil)
  if valid_606241 != nil:
    section.add "Signature", valid_606241
  var valid_606242 = query.getOrDefault("name")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "name", valid_606242
  var valid_606243 = query.getOrDefault("street2")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "street2", valid_606243
  var valid_606244 = query.getOrDefault("street3")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "street3", valid_606244
  var valid_606245 = query.getOrDefault("AWSAccessKeyId")
  valid_606245 = validateParameter(valid_606245, JString, required = true,
                                 default = nil)
  if valid_606245 != nil:
    section.add "AWSAccessKeyId", valid_606245
  var valid_606246 = query.getOrDefault("SignatureMethod")
  valid_606246 = validateParameter(valid_606246, JString, required = true,
                                 default = nil)
  if valid_606246 != nil:
    section.add "SignatureMethod", valid_606246
  var valid_606247 = query.getOrDefault("phoneNumber")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "phoneNumber", valid_606247
  var valid_606248 = query.getOrDefault("postalCode")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "postalCode", valid_606248
  var valid_606249 = query.getOrDefault("street1")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "street1", valid_606249
  var valid_606250 = query.getOrDefault("city")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "city", valid_606250
  var valid_606251 = query.getOrDefault("country")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "country", valid_606251
  var valid_606252 = query.getOrDefault("Timestamp")
  valid_606252 = validateParameter(valid_606252, JString, required = true,
                                 default = nil)
  if valid_606252 != nil:
    section.add "Timestamp", valid_606252
  var valid_606253 = query.getOrDefault("Action")
  valid_606253 = validateParameter(valid_606253, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_606253 != nil:
    section.add "Action", valid_606253
  var valid_606254 = query.getOrDefault("jobIds")
  valid_606254 = validateParameter(valid_606254, JArray, required = true, default = nil)
  if valid_606254 != nil:
    section.add "jobIds", valid_606254
  var valid_606255 = query.getOrDefault("Operation")
  valid_606255 = validateParameter(valid_606255, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_606255 != nil:
    section.add "Operation", valid_606255
  var valid_606256 = query.getOrDefault("APIVersion")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "APIVersion", valid_606256
  var valid_606257 = query.getOrDefault("Version")
  valid_606257 = validateParameter(valid_606257, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606257 != nil:
    section.add "Version", valid_606257
  var valid_606258 = query.getOrDefault("stateOrProvince")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "stateOrProvince", valid_606258
  var valid_606259 = query.getOrDefault("SignatureVersion")
  valid_606259 = validateParameter(valid_606259, JString, required = true,
                                 default = nil)
  if valid_606259 != nil:
    section.add "SignatureVersion", valid_606259
  var valid_606260 = query.getOrDefault("company")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "company", valid_606260
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606261: Call_GetGetShippingLabel_606238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_606261.validator(path, query, header, formData, body)
  let scheme = call_606261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606261.url(scheme.get, call_606261.host, call_606261.base,
                         call_606261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606261, url, valid)

proc call*(call_606262: Call_GetGetShippingLabel_606238; Signature: string;
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
  var query_606263 = newJObject()
  add(query_606263, "Signature", newJString(Signature))
  add(query_606263, "name", newJString(name))
  add(query_606263, "street2", newJString(street2))
  add(query_606263, "street3", newJString(street3))
  add(query_606263, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606263, "SignatureMethod", newJString(SignatureMethod))
  add(query_606263, "phoneNumber", newJString(phoneNumber))
  add(query_606263, "postalCode", newJString(postalCode))
  add(query_606263, "street1", newJString(street1))
  add(query_606263, "city", newJString(city))
  add(query_606263, "country", newJString(country))
  add(query_606263, "Timestamp", newJString(Timestamp))
  add(query_606263, "Action", newJString(Action))
  if jobIds != nil:
    query_606263.add "jobIds", jobIds
  add(query_606263, "Operation", newJString(Operation))
  add(query_606263, "APIVersion", newJString(APIVersion))
  add(query_606263, "Version", newJString(Version))
  add(query_606263, "stateOrProvince", newJString(stateOrProvince))
  add(query_606263, "SignatureVersion", newJString(SignatureVersion))
  add(query_606263, "company", newJString(company))
  result = call_606262.call(nil, query_606263, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_606238(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_606239, base: "/",
    url: url_GetGetShippingLabel_606240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_606307 = ref object of OpenApiRestCall_605573
proc url_PostGetStatus_606309(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetStatus_606308(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606310 = query.getOrDefault("Signature")
  valid_606310 = validateParameter(valid_606310, JString, required = true,
                                 default = nil)
  if valid_606310 != nil:
    section.add "Signature", valid_606310
  var valid_606311 = query.getOrDefault("AWSAccessKeyId")
  valid_606311 = validateParameter(valid_606311, JString, required = true,
                                 default = nil)
  if valid_606311 != nil:
    section.add "AWSAccessKeyId", valid_606311
  var valid_606312 = query.getOrDefault("SignatureMethod")
  valid_606312 = validateParameter(valid_606312, JString, required = true,
                                 default = nil)
  if valid_606312 != nil:
    section.add "SignatureMethod", valid_606312
  var valid_606313 = query.getOrDefault("Timestamp")
  valid_606313 = validateParameter(valid_606313, JString, required = true,
                                 default = nil)
  if valid_606313 != nil:
    section.add "Timestamp", valid_606313
  var valid_606314 = query.getOrDefault("Action")
  valid_606314 = validateParameter(valid_606314, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_606314 != nil:
    section.add "Action", valid_606314
  var valid_606315 = query.getOrDefault("Operation")
  valid_606315 = validateParameter(valid_606315, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_606315 != nil:
    section.add "Operation", valid_606315
  var valid_606316 = query.getOrDefault("Version")
  valid_606316 = validateParameter(valid_606316, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606316 != nil:
    section.add "Version", valid_606316
  var valid_606317 = query.getOrDefault("SignatureVersion")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = nil)
  if valid_606317 != nil:
    section.add "SignatureVersion", valid_606317
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_606318 = formData.getOrDefault("APIVersion")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "APIVersion", valid_606318
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_606319 = formData.getOrDefault("JobId")
  valid_606319 = validateParameter(valid_606319, JString, required = true,
                                 default = nil)
  if valid_606319 != nil:
    section.add "JobId", valid_606319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_PostGetStatus_606307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_PostGetStatus_606307; Signature: string;
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
  var query_606322 = newJObject()
  var formData_606323 = newJObject()
  add(query_606322, "Signature", newJString(Signature))
  add(query_606322, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606322, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606323, "APIVersion", newJString(APIVersion))
  add(query_606322, "Timestamp", newJString(Timestamp))
  add(query_606322, "Action", newJString(Action))
  add(query_606322, "Operation", newJString(Operation))
  add(formData_606323, "JobId", newJString(JobId))
  add(query_606322, "Version", newJString(Version))
  add(query_606322, "SignatureVersion", newJString(SignatureVersion))
  result = call_606321.call(nil, query_606322, nil, formData_606323, nil)

var postGetStatus* = Call_PostGetStatus_606307(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_606308, base: "/", url: url_PostGetStatus_606309,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_606291 = ref object of OpenApiRestCall_605573
proc url_GetGetStatus_606293(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetStatus_606292(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606294 = query.getOrDefault("Signature")
  valid_606294 = validateParameter(valid_606294, JString, required = true,
                                 default = nil)
  if valid_606294 != nil:
    section.add "Signature", valid_606294
  var valid_606295 = query.getOrDefault("AWSAccessKeyId")
  valid_606295 = validateParameter(valid_606295, JString, required = true,
                                 default = nil)
  if valid_606295 != nil:
    section.add "AWSAccessKeyId", valid_606295
  var valid_606296 = query.getOrDefault("SignatureMethod")
  valid_606296 = validateParameter(valid_606296, JString, required = true,
                                 default = nil)
  if valid_606296 != nil:
    section.add "SignatureMethod", valid_606296
  var valid_606297 = query.getOrDefault("Timestamp")
  valid_606297 = validateParameter(valid_606297, JString, required = true,
                                 default = nil)
  if valid_606297 != nil:
    section.add "Timestamp", valid_606297
  var valid_606298 = query.getOrDefault("Action")
  valid_606298 = validateParameter(valid_606298, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_606298 != nil:
    section.add "Action", valid_606298
  var valid_606299 = query.getOrDefault("Operation")
  valid_606299 = validateParameter(valid_606299, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_606299 != nil:
    section.add "Operation", valid_606299
  var valid_606300 = query.getOrDefault("APIVersion")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "APIVersion", valid_606300
  var valid_606301 = query.getOrDefault("Version")
  valid_606301 = validateParameter(valid_606301, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606301 != nil:
    section.add "Version", valid_606301
  var valid_606302 = query.getOrDefault("JobId")
  valid_606302 = validateParameter(valid_606302, JString, required = true,
                                 default = nil)
  if valid_606302 != nil:
    section.add "JobId", valid_606302
  var valid_606303 = query.getOrDefault("SignatureVersion")
  valid_606303 = validateParameter(valid_606303, JString, required = true,
                                 default = nil)
  if valid_606303 != nil:
    section.add "SignatureVersion", valid_606303
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606304: Call_GetGetStatus_606291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_606304.validator(path, query, header, formData, body)
  let scheme = call_606304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606304.url(scheme.get, call_606304.host, call_606304.base,
                         call_606304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606304, url, valid)

proc call*(call_606305: Call_GetGetStatus_606291; Signature: string;
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
  var query_606306 = newJObject()
  add(query_606306, "Signature", newJString(Signature))
  add(query_606306, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606306, "SignatureMethod", newJString(SignatureMethod))
  add(query_606306, "Timestamp", newJString(Timestamp))
  add(query_606306, "Action", newJString(Action))
  add(query_606306, "Operation", newJString(Operation))
  add(query_606306, "APIVersion", newJString(APIVersion))
  add(query_606306, "Version", newJString(Version))
  add(query_606306, "JobId", newJString(JobId))
  add(query_606306, "SignatureVersion", newJString(SignatureVersion))
  result = call_606305.call(nil, query_606306, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_606291(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_606292, base: "/", url: url_GetGetStatus_606293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_606341 = ref object of OpenApiRestCall_605573
proc url_PostListJobs_606343(protocol: Scheme; host: string; base: string;
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

proc validate_PostListJobs_606342(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606344 = query.getOrDefault("Signature")
  valid_606344 = validateParameter(valid_606344, JString, required = true,
                                 default = nil)
  if valid_606344 != nil:
    section.add "Signature", valid_606344
  var valid_606345 = query.getOrDefault("AWSAccessKeyId")
  valid_606345 = validateParameter(valid_606345, JString, required = true,
                                 default = nil)
  if valid_606345 != nil:
    section.add "AWSAccessKeyId", valid_606345
  var valid_606346 = query.getOrDefault("SignatureMethod")
  valid_606346 = validateParameter(valid_606346, JString, required = true,
                                 default = nil)
  if valid_606346 != nil:
    section.add "SignatureMethod", valid_606346
  var valid_606347 = query.getOrDefault("Timestamp")
  valid_606347 = validateParameter(valid_606347, JString, required = true,
                                 default = nil)
  if valid_606347 != nil:
    section.add "Timestamp", valid_606347
  var valid_606348 = query.getOrDefault("Action")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_606348 != nil:
    section.add "Action", valid_606348
  var valid_606349 = query.getOrDefault("Operation")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_606349 != nil:
    section.add "Operation", valid_606349
  var valid_606350 = query.getOrDefault("Version")
  valid_606350 = validateParameter(valid_606350, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606350 != nil:
    section.add "Version", valid_606350
  var valid_606351 = query.getOrDefault("SignatureVersion")
  valid_606351 = validateParameter(valid_606351, JString, required = true,
                                 default = nil)
  if valid_606351 != nil:
    section.add "SignatureVersion", valid_606351
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
  var valid_606352 = formData.getOrDefault("MaxJobs")
  valid_606352 = validateParameter(valid_606352, JInt, required = false, default = nil)
  if valid_606352 != nil:
    section.add "MaxJobs", valid_606352
  var valid_606353 = formData.getOrDefault("Marker")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "Marker", valid_606353
  var valid_606354 = formData.getOrDefault("APIVersion")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "APIVersion", valid_606354
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606355: Call_PostListJobs_606341; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_606355.validator(path, query, header, formData, body)
  let scheme = call_606355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606355.url(scheme.get, call_606355.host, call_606355.base,
                         call_606355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606355, url, valid)

proc call*(call_606356: Call_PostListJobs_606341; Signature: string;
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
  var query_606357 = newJObject()
  var formData_606358 = newJObject()
  add(query_606357, "Signature", newJString(Signature))
  add(formData_606358, "MaxJobs", newJInt(MaxJobs))
  add(query_606357, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606357, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606358, "Marker", newJString(Marker))
  add(formData_606358, "APIVersion", newJString(APIVersion))
  add(query_606357, "Timestamp", newJString(Timestamp))
  add(query_606357, "Action", newJString(Action))
  add(query_606357, "Operation", newJString(Operation))
  add(query_606357, "Version", newJString(Version))
  add(query_606357, "SignatureVersion", newJString(SignatureVersion))
  result = call_606356.call(nil, query_606357, nil, formData_606358, nil)

var postListJobs* = Call_PostListJobs_606341(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_606342, base: "/", url: url_PostListJobs_606343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_606324 = ref object of OpenApiRestCall_605573
proc url_GetListJobs_606326(protocol: Scheme; host: string; base: string;
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

proc validate_GetListJobs_606325(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606327 = query.getOrDefault("MaxJobs")
  valid_606327 = validateParameter(valid_606327, JInt, required = false, default = nil)
  if valid_606327 != nil:
    section.add "MaxJobs", valid_606327
  var valid_606328 = query.getOrDefault("Marker")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "Marker", valid_606328
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_606329 = query.getOrDefault("Signature")
  valid_606329 = validateParameter(valid_606329, JString, required = true,
                                 default = nil)
  if valid_606329 != nil:
    section.add "Signature", valid_606329
  var valid_606330 = query.getOrDefault("AWSAccessKeyId")
  valid_606330 = validateParameter(valid_606330, JString, required = true,
                                 default = nil)
  if valid_606330 != nil:
    section.add "AWSAccessKeyId", valid_606330
  var valid_606331 = query.getOrDefault("SignatureMethod")
  valid_606331 = validateParameter(valid_606331, JString, required = true,
                                 default = nil)
  if valid_606331 != nil:
    section.add "SignatureMethod", valid_606331
  var valid_606332 = query.getOrDefault("Timestamp")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = nil)
  if valid_606332 != nil:
    section.add "Timestamp", valid_606332
  var valid_606333 = query.getOrDefault("Action")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_606333 != nil:
    section.add "Action", valid_606333
  var valid_606334 = query.getOrDefault("Operation")
  valid_606334 = validateParameter(valid_606334, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_606334 != nil:
    section.add "Operation", valid_606334
  var valid_606335 = query.getOrDefault("APIVersion")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "APIVersion", valid_606335
  var valid_606336 = query.getOrDefault("Version")
  valid_606336 = validateParameter(valid_606336, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606336 != nil:
    section.add "Version", valid_606336
  var valid_606337 = query.getOrDefault("SignatureVersion")
  valid_606337 = validateParameter(valid_606337, JString, required = true,
                                 default = nil)
  if valid_606337 != nil:
    section.add "SignatureVersion", valid_606337
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606338: Call_GetListJobs_606324; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_606338.validator(path, query, header, formData, body)
  let scheme = call_606338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606338.url(scheme.get, call_606338.host, call_606338.base,
                         call_606338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606338, url, valid)

proc call*(call_606339: Call_GetListJobs_606324; Signature: string;
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
  var query_606340 = newJObject()
  add(query_606340, "MaxJobs", newJInt(MaxJobs))
  add(query_606340, "Marker", newJString(Marker))
  add(query_606340, "Signature", newJString(Signature))
  add(query_606340, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606340, "SignatureMethod", newJString(SignatureMethod))
  add(query_606340, "Timestamp", newJString(Timestamp))
  add(query_606340, "Action", newJString(Action))
  add(query_606340, "Operation", newJString(Operation))
  add(query_606340, "APIVersion", newJString(APIVersion))
  add(query_606340, "Version", newJString(Version))
  add(query_606340, "SignatureVersion", newJString(SignatureVersion))
  result = call_606339.call(nil, query_606340, nil, nil, nil)

var getListJobs* = Call_GetListJobs_606324(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_606325,
                                        base: "/", url: url_GetListJobs_606326,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_606378 = ref object of OpenApiRestCall_605573
proc url_PostUpdateJob_606380(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateJob_606379(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606381 = query.getOrDefault("Signature")
  valid_606381 = validateParameter(valid_606381, JString, required = true,
                                 default = nil)
  if valid_606381 != nil:
    section.add "Signature", valid_606381
  var valid_606382 = query.getOrDefault("AWSAccessKeyId")
  valid_606382 = validateParameter(valid_606382, JString, required = true,
                                 default = nil)
  if valid_606382 != nil:
    section.add "AWSAccessKeyId", valid_606382
  var valid_606383 = query.getOrDefault("SignatureMethod")
  valid_606383 = validateParameter(valid_606383, JString, required = true,
                                 default = nil)
  if valid_606383 != nil:
    section.add "SignatureMethod", valid_606383
  var valid_606384 = query.getOrDefault("Timestamp")
  valid_606384 = validateParameter(valid_606384, JString, required = true,
                                 default = nil)
  if valid_606384 != nil:
    section.add "Timestamp", valid_606384
  var valid_606385 = query.getOrDefault("Action")
  valid_606385 = validateParameter(valid_606385, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_606385 != nil:
    section.add "Action", valid_606385
  var valid_606386 = query.getOrDefault("Operation")
  valid_606386 = validateParameter(valid_606386, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_606386 != nil:
    section.add "Operation", valid_606386
  var valid_606387 = query.getOrDefault("Version")
  valid_606387 = validateParameter(valid_606387, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606387 != nil:
    section.add "Version", valid_606387
  var valid_606388 = query.getOrDefault("SignatureVersion")
  valid_606388 = validateParameter(valid_606388, JString, required = true,
                                 default = nil)
  if valid_606388 != nil:
    section.add "SignatureVersion", valid_606388
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
  var valid_606389 = formData.getOrDefault("ValidateOnly")
  valid_606389 = validateParameter(valid_606389, JBool, required = true, default = nil)
  if valid_606389 != nil:
    section.add "ValidateOnly", valid_606389
  var valid_606390 = formData.getOrDefault("APIVersion")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "APIVersion", valid_606390
  var valid_606391 = formData.getOrDefault("JobId")
  valid_606391 = validateParameter(valid_606391, JString, required = true,
                                 default = nil)
  if valid_606391 != nil:
    section.add "JobId", valid_606391
  var valid_606392 = formData.getOrDefault("JobType")
  valid_606392 = validateParameter(valid_606392, JString, required = true,
                                 default = newJString("Import"))
  if valid_606392 != nil:
    section.add "JobType", valid_606392
  var valid_606393 = formData.getOrDefault("Manifest")
  valid_606393 = validateParameter(valid_606393, JString, required = true,
                                 default = nil)
  if valid_606393 != nil:
    section.add "Manifest", valid_606393
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606394: Call_PostUpdateJob_606378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_606394.validator(path, query, header, formData, body)
  let scheme = call_606394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606394.url(scheme.get, call_606394.host, call_606394.base,
                         call_606394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606394, url, valid)

proc call*(call_606395: Call_PostUpdateJob_606378; Signature: string;
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
  var query_606396 = newJObject()
  var formData_606397 = newJObject()
  add(query_606396, "Signature", newJString(Signature))
  add(query_606396, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606396, "SignatureMethod", newJString(SignatureMethod))
  add(formData_606397, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_606397, "APIVersion", newJString(APIVersion))
  add(query_606396, "Timestamp", newJString(Timestamp))
  add(query_606396, "Action", newJString(Action))
  add(query_606396, "Operation", newJString(Operation))
  add(formData_606397, "JobId", newJString(JobId))
  add(query_606396, "Version", newJString(Version))
  add(formData_606397, "JobType", newJString(JobType))
  add(query_606396, "SignatureVersion", newJString(SignatureVersion))
  add(formData_606397, "Manifest", newJString(Manifest))
  result = call_606395.call(nil, query_606396, nil, formData_606397, nil)

var postUpdateJob* = Call_PostUpdateJob_606378(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_606379, base: "/", url: url_PostUpdateJob_606380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_606359 = ref object of OpenApiRestCall_605573
proc url_GetUpdateJob_606361(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateJob_606360(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606362 = query.getOrDefault("Signature")
  valid_606362 = validateParameter(valid_606362, JString, required = true,
                                 default = nil)
  if valid_606362 != nil:
    section.add "Signature", valid_606362
  var valid_606363 = query.getOrDefault("JobType")
  valid_606363 = validateParameter(valid_606363, JString, required = true,
                                 default = newJString("Import"))
  if valid_606363 != nil:
    section.add "JobType", valid_606363
  var valid_606364 = query.getOrDefault("AWSAccessKeyId")
  valid_606364 = validateParameter(valid_606364, JString, required = true,
                                 default = nil)
  if valid_606364 != nil:
    section.add "AWSAccessKeyId", valid_606364
  var valid_606365 = query.getOrDefault("SignatureMethod")
  valid_606365 = validateParameter(valid_606365, JString, required = true,
                                 default = nil)
  if valid_606365 != nil:
    section.add "SignatureMethod", valid_606365
  var valid_606366 = query.getOrDefault("Manifest")
  valid_606366 = validateParameter(valid_606366, JString, required = true,
                                 default = nil)
  if valid_606366 != nil:
    section.add "Manifest", valid_606366
  var valid_606367 = query.getOrDefault("ValidateOnly")
  valid_606367 = validateParameter(valid_606367, JBool, required = true, default = nil)
  if valid_606367 != nil:
    section.add "ValidateOnly", valid_606367
  var valid_606368 = query.getOrDefault("Timestamp")
  valid_606368 = validateParameter(valid_606368, JString, required = true,
                                 default = nil)
  if valid_606368 != nil:
    section.add "Timestamp", valid_606368
  var valid_606369 = query.getOrDefault("Action")
  valid_606369 = validateParameter(valid_606369, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_606369 != nil:
    section.add "Action", valid_606369
  var valid_606370 = query.getOrDefault("Operation")
  valid_606370 = validateParameter(valid_606370, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_606370 != nil:
    section.add "Operation", valid_606370
  var valid_606371 = query.getOrDefault("APIVersion")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "APIVersion", valid_606371
  var valid_606372 = query.getOrDefault("Version")
  valid_606372 = validateParameter(valid_606372, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_606372 != nil:
    section.add "Version", valid_606372
  var valid_606373 = query.getOrDefault("JobId")
  valid_606373 = validateParameter(valid_606373, JString, required = true,
                                 default = nil)
  if valid_606373 != nil:
    section.add "JobId", valid_606373
  var valid_606374 = query.getOrDefault("SignatureVersion")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "SignatureVersion", valid_606374
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606375: Call_GetUpdateJob_606359; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_606375.validator(path, query, header, formData, body)
  let scheme = call_606375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606375.url(scheme.get, call_606375.host, call_606375.base,
                         call_606375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606375, url, valid)

proc call*(call_606376: Call_GetUpdateJob_606359; Signature: string;
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
  var query_606377 = newJObject()
  add(query_606377, "Signature", newJString(Signature))
  add(query_606377, "JobType", newJString(JobType))
  add(query_606377, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_606377, "SignatureMethod", newJString(SignatureMethod))
  add(query_606377, "Manifest", newJString(Manifest))
  add(query_606377, "ValidateOnly", newJBool(ValidateOnly))
  add(query_606377, "Timestamp", newJString(Timestamp))
  add(query_606377, "Action", newJString(Action))
  add(query_606377, "Operation", newJString(Operation))
  add(query_606377, "APIVersion", newJString(APIVersion))
  add(query_606377, "Version", newJString(Version))
  add(query_606377, "JobId", newJString(JobId))
  add(query_606377, "SignatureVersion", newJString(SignatureVersion))
  result = call_606376.call(nil, query_606377, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_606359(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_606360, base: "/", url: url_GetUpdateJob_606361,
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
