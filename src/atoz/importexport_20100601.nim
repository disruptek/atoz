
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592348 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592348](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592348): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCancelJob_592958 = ref object of OpenApiRestCall_592348
proc url_PostCancelJob_592960(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCancelJob_592959(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592961 = query.getOrDefault("Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = true,
                                 default = nil)
  if valid_592961 != nil:
    section.add "Signature", valid_592961
  var valid_592962 = query.getOrDefault("AWSAccessKeyId")
  valid_592962 = validateParameter(valid_592962, JString, required = true,
                                 default = nil)
  if valid_592962 != nil:
    section.add "AWSAccessKeyId", valid_592962
  var valid_592963 = query.getOrDefault("SignatureMethod")
  valid_592963 = validateParameter(valid_592963, JString, required = true,
                                 default = nil)
  if valid_592963 != nil:
    section.add "SignatureMethod", valid_592963
  var valid_592964 = query.getOrDefault("Timestamp")
  valid_592964 = validateParameter(valid_592964, JString, required = true,
                                 default = nil)
  if valid_592964 != nil:
    section.add "Timestamp", valid_592964
  var valid_592965 = query.getOrDefault("Action")
  valid_592965 = validateParameter(valid_592965, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_592965 != nil:
    section.add "Action", valid_592965
  var valid_592966 = query.getOrDefault("Operation")
  valid_592966 = validateParameter(valid_592966, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_592966 != nil:
    section.add "Operation", valid_592966
  var valid_592967 = query.getOrDefault("Version")
  valid_592967 = validateParameter(valid_592967, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_592967 != nil:
    section.add "Version", valid_592967
  var valid_592968 = query.getOrDefault("SignatureVersion")
  valid_592968 = validateParameter(valid_592968, JString, required = true,
                                 default = nil)
  if valid_592968 != nil:
    section.add "SignatureVersion", valid_592968
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_592969 = formData.getOrDefault("APIVersion")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "APIVersion", valid_592969
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_592970 = formData.getOrDefault("JobId")
  valid_592970 = validateParameter(valid_592970, JString, required = true,
                                 default = nil)
  if valid_592970 != nil:
    section.add "JobId", valid_592970
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592971: Call_PostCancelJob_592958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_592971.validator(path, query, header, formData, body)
  let scheme = call_592971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592971.url(scheme.get, call_592971.host, call_592971.base,
                         call_592971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592971, url, valid)

proc call*(call_592972: Call_PostCancelJob_592958; Signature: string;
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
  var query_592973 = newJObject()
  var formData_592974 = newJObject()
  add(query_592973, "Signature", newJString(Signature))
  add(query_592973, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_592973, "SignatureMethod", newJString(SignatureMethod))
  add(formData_592974, "APIVersion", newJString(APIVersion))
  add(query_592973, "Timestamp", newJString(Timestamp))
  add(query_592973, "Action", newJString(Action))
  add(query_592973, "Operation", newJString(Operation))
  add(formData_592974, "JobId", newJString(JobId))
  add(query_592973, "Version", newJString(Version))
  add(query_592973, "SignatureVersion", newJString(SignatureVersion))
  result = call_592972.call(nil, query_592973, nil, formData_592974, nil)

var postCancelJob* = Call_PostCancelJob_592958(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_592959, base: "/", url: url_PostCancelJob_592960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_592687 = ref object of OpenApiRestCall_592348
proc url_GetCancelJob_592689(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCancelJob_592688(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592801 = query.getOrDefault("Signature")
  valid_592801 = validateParameter(valid_592801, JString, required = true,
                                 default = nil)
  if valid_592801 != nil:
    section.add "Signature", valid_592801
  var valid_592802 = query.getOrDefault("AWSAccessKeyId")
  valid_592802 = validateParameter(valid_592802, JString, required = true,
                                 default = nil)
  if valid_592802 != nil:
    section.add "AWSAccessKeyId", valid_592802
  var valid_592803 = query.getOrDefault("SignatureMethod")
  valid_592803 = validateParameter(valid_592803, JString, required = true,
                                 default = nil)
  if valid_592803 != nil:
    section.add "SignatureMethod", valid_592803
  var valid_592804 = query.getOrDefault("Timestamp")
  valid_592804 = validateParameter(valid_592804, JString, required = true,
                                 default = nil)
  if valid_592804 != nil:
    section.add "Timestamp", valid_592804
  var valid_592818 = query.getOrDefault("Action")
  valid_592818 = validateParameter(valid_592818, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_592818 != nil:
    section.add "Action", valid_592818
  var valid_592819 = query.getOrDefault("Operation")
  valid_592819 = validateParameter(valid_592819, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_592819 != nil:
    section.add "Operation", valid_592819
  var valid_592820 = query.getOrDefault("APIVersion")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "APIVersion", valid_592820
  var valid_592821 = query.getOrDefault("Version")
  valid_592821 = validateParameter(valid_592821, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_592821 != nil:
    section.add "Version", valid_592821
  var valid_592822 = query.getOrDefault("JobId")
  valid_592822 = validateParameter(valid_592822, JString, required = true,
                                 default = nil)
  if valid_592822 != nil:
    section.add "JobId", valid_592822
  var valid_592823 = query.getOrDefault("SignatureVersion")
  valid_592823 = validateParameter(valid_592823, JString, required = true,
                                 default = nil)
  if valid_592823 != nil:
    section.add "SignatureVersion", valid_592823
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592846: Call_GetCancelJob_592687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_592846.validator(path, query, header, formData, body)
  let scheme = call_592846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592846.url(scheme.get, call_592846.host, call_592846.base,
                         call_592846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592846, url, valid)

proc call*(call_592917: Call_GetCancelJob_592687; Signature: string;
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
  var query_592918 = newJObject()
  add(query_592918, "Signature", newJString(Signature))
  add(query_592918, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_592918, "SignatureMethod", newJString(SignatureMethod))
  add(query_592918, "Timestamp", newJString(Timestamp))
  add(query_592918, "Action", newJString(Action))
  add(query_592918, "Operation", newJString(Operation))
  add(query_592918, "APIVersion", newJString(APIVersion))
  add(query_592918, "Version", newJString(Version))
  add(query_592918, "JobId", newJString(JobId))
  add(query_592918, "SignatureVersion", newJString(SignatureVersion))
  result = call_592917.call(nil, query_592918, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_592687(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_592688, base: "/", url: url_GetCancelJob_592689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_592994 = ref object of OpenApiRestCall_592348
proc url_PostCreateJob_592996(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateJob_592995(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592997 = query.getOrDefault("Signature")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "Signature", valid_592997
  var valid_592998 = query.getOrDefault("AWSAccessKeyId")
  valid_592998 = validateParameter(valid_592998, JString, required = true,
                                 default = nil)
  if valid_592998 != nil:
    section.add "AWSAccessKeyId", valid_592998
  var valid_592999 = query.getOrDefault("SignatureMethod")
  valid_592999 = validateParameter(valid_592999, JString, required = true,
                                 default = nil)
  if valid_592999 != nil:
    section.add "SignatureMethod", valid_592999
  var valid_593000 = query.getOrDefault("Timestamp")
  valid_593000 = validateParameter(valid_593000, JString, required = true,
                                 default = nil)
  if valid_593000 != nil:
    section.add "Timestamp", valid_593000
  var valid_593001 = query.getOrDefault("Action")
  valid_593001 = validateParameter(valid_593001, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_593001 != nil:
    section.add "Action", valid_593001
  var valid_593002 = query.getOrDefault("Operation")
  valid_593002 = validateParameter(valid_593002, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_593002 != nil:
    section.add "Operation", valid_593002
  var valid_593003 = query.getOrDefault("Version")
  valid_593003 = validateParameter(valid_593003, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593003 != nil:
    section.add "Version", valid_593003
  var valid_593004 = query.getOrDefault("SignatureVersion")
  valid_593004 = validateParameter(valid_593004, JString, required = true,
                                 default = nil)
  if valid_593004 != nil:
    section.add "SignatureVersion", valid_593004
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
  var valid_593005 = formData.getOrDefault("ValidateOnly")
  valid_593005 = validateParameter(valid_593005, JBool, required = true, default = nil)
  if valid_593005 != nil:
    section.add "ValidateOnly", valid_593005
  var valid_593006 = formData.getOrDefault("APIVersion")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "APIVersion", valid_593006
  var valid_593007 = formData.getOrDefault("ManifestAddendum")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "ManifestAddendum", valid_593007
  var valid_593008 = formData.getOrDefault("JobType")
  valid_593008 = validateParameter(valid_593008, JString, required = true,
                                 default = newJString("Import"))
  if valid_593008 != nil:
    section.add "JobType", valid_593008
  var valid_593009 = formData.getOrDefault("Manifest")
  valid_593009 = validateParameter(valid_593009, JString, required = true,
                                 default = nil)
  if valid_593009 != nil:
    section.add "Manifest", valid_593009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593010: Call_PostCreateJob_592994; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_593010.validator(path, query, header, formData, body)
  let scheme = call_593010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593010.url(scheme.get, call_593010.host, call_593010.base,
                         call_593010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593010, url, valid)

proc call*(call_593011: Call_PostCreateJob_592994; Signature: string;
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
  var query_593012 = newJObject()
  var formData_593013 = newJObject()
  add(query_593012, "Signature", newJString(Signature))
  add(query_593012, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593012, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593013, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_593013, "APIVersion", newJString(APIVersion))
  add(query_593012, "Timestamp", newJString(Timestamp))
  add(query_593012, "Action", newJString(Action))
  add(formData_593013, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_593012, "Operation", newJString(Operation))
  add(query_593012, "Version", newJString(Version))
  add(formData_593013, "JobType", newJString(JobType))
  add(query_593012, "SignatureVersion", newJString(SignatureVersion))
  add(formData_593013, "Manifest", newJString(Manifest))
  result = call_593011.call(nil, query_593012, nil, formData_593013, nil)

var postCreateJob* = Call_PostCreateJob_592994(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_592995, base: "/", url: url_PostCreateJob_592996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_592975 = ref object of OpenApiRestCall_592348
proc url_GetCreateJob_592977(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateJob_592976(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592978 = query.getOrDefault("Signature")
  valid_592978 = validateParameter(valid_592978, JString, required = true,
                                 default = nil)
  if valid_592978 != nil:
    section.add "Signature", valid_592978
  var valid_592979 = query.getOrDefault("JobType")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = newJString("Import"))
  if valid_592979 != nil:
    section.add "JobType", valid_592979
  var valid_592980 = query.getOrDefault("AWSAccessKeyId")
  valid_592980 = validateParameter(valid_592980, JString, required = true,
                                 default = nil)
  if valid_592980 != nil:
    section.add "AWSAccessKeyId", valid_592980
  var valid_592981 = query.getOrDefault("SignatureMethod")
  valid_592981 = validateParameter(valid_592981, JString, required = true,
                                 default = nil)
  if valid_592981 != nil:
    section.add "SignatureMethod", valid_592981
  var valid_592982 = query.getOrDefault("Manifest")
  valid_592982 = validateParameter(valid_592982, JString, required = true,
                                 default = nil)
  if valid_592982 != nil:
    section.add "Manifest", valid_592982
  var valid_592983 = query.getOrDefault("ValidateOnly")
  valid_592983 = validateParameter(valid_592983, JBool, required = true, default = nil)
  if valid_592983 != nil:
    section.add "ValidateOnly", valid_592983
  var valid_592984 = query.getOrDefault("Timestamp")
  valid_592984 = validateParameter(valid_592984, JString, required = true,
                                 default = nil)
  if valid_592984 != nil:
    section.add "Timestamp", valid_592984
  var valid_592985 = query.getOrDefault("Action")
  valid_592985 = validateParameter(valid_592985, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_592985 != nil:
    section.add "Action", valid_592985
  var valid_592986 = query.getOrDefault("ManifestAddendum")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "ManifestAddendum", valid_592986
  var valid_592987 = query.getOrDefault("Operation")
  valid_592987 = validateParameter(valid_592987, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_592987 != nil:
    section.add "Operation", valid_592987
  var valid_592988 = query.getOrDefault("APIVersion")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "APIVersion", valid_592988
  var valid_592989 = query.getOrDefault("Version")
  valid_592989 = validateParameter(valid_592989, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_592989 != nil:
    section.add "Version", valid_592989
  var valid_592990 = query.getOrDefault("SignatureVersion")
  valid_592990 = validateParameter(valid_592990, JString, required = true,
                                 default = nil)
  if valid_592990 != nil:
    section.add "SignatureVersion", valid_592990
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592991: Call_GetCreateJob_592975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_592991.validator(path, query, header, formData, body)
  let scheme = call_592991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592991.url(scheme.get, call_592991.host, call_592991.base,
                         call_592991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592991, url, valid)

proc call*(call_592992: Call_GetCreateJob_592975; Signature: string;
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
  var query_592993 = newJObject()
  add(query_592993, "Signature", newJString(Signature))
  add(query_592993, "JobType", newJString(JobType))
  add(query_592993, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_592993, "SignatureMethod", newJString(SignatureMethod))
  add(query_592993, "Manifest", newJString(Manifest))
  add(query_592993, "ValidateOnly", newJBool(ValidateOnly))
  add(query_592993, "Timestamp", newJString(Timestamp))
  add(query_592993, "Action", newJString(Action))
  add(query_592993, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_592993, "Operation", newJString(Operation))
  add(query_592993, "APIVersion", newJString(APIVersion))
  add(query_592993, "Version", newJString(Version))
  add(query_592993, "SignatureVersion", newJString(SignatureVersion))
  result = call_592992.call(nil, query_592993, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_592975(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_592976, base: "/", url: url_GetCreateJob_592977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_593040 = ref object of OpenApiRestCall_592348
proc url_PostGetShippingLabel_593042(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetShippingLabel_593041(path: JsonNode; query: JsonNode;
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
  var valid_593043 = query.getOrDefault("Signature")
  valid_593043 = validateParameter(valid_593043, JString, required = true,
                                 default = nil)
  if valid_593043 != nil:
    section.add "Signature", valid_593043
  var valid_593044 = query.getOrDefault("AWSAccessKeyId")
  valid_593044 = validateParameter(valid_593044, JString, required = true,
                                 default = nil)
  if valid_593044 != nil:
    section.add "AWSAccessKeyId", valid_593044
  var valid_593045 = query.getOrDefault("SignatureMethod")
  valid_593045 = validateParameter(valid_593045, JString, required = true,
                                 default = nil)
  if valid_593045 != nil:
    section.add "SignatureMethod", valid_593045
  var valid_593046 = query.getOrDefault("Timestamp")
  valid_593046 = validateParameter(valid_593046, JString, required = true,
                                 default = nil)
  if valid_593046 != nil:
    section.add "Timestamp", valid_593046
  var valid_593047 = query.getOrDefault("Action")
  valid_593047 = validateParameter(valid_593047, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_593047 != nil:
    section.add "Action", valid_593047
  var valid_593048 = query.getOrDefault("Operation")
  valid_593048 = validateParameter(valid_593048, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_593048 != nil:
    section.add "Operation", valid_593048
  var valid_593049 = query.getOrDefault("Version")
  valid_593049 = validateParameter(valid_593049, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593049 != nil:
    section.add "Version", valid_593049
  var valid_593050 = query.getOrDefault("SignatureVersion")
  valid_593050 = validateParameter(valid_593050, JString, required = true,
                                 default = nil)
  if valid_593050 != nil:
    section.add "SignatureVersion", valid_593050
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
  var valid_593051 = formData.getOrDefault("street1")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "street1", valid_593051
  var valid_593052 = formData.getOrDefault("stateOrProvince")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "stateOrProvince", valid_593052
  var valid_593053 = formData.getOrDefault("street3")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "street3", valid_593053
  var valid_593054 = formData.getOrDefault("phoneNumber")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "phoneNumber", valid_593054
  var valid_593055 = formData.getOrDefault("postalCode")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "postalCode", valid_593055
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_593056 = formData.getOrDefault("jobIds")
  valid_593056 = validateParameter(valid_593056, JArray, required = true, default = nil)
  if valid_593056 != nil:
    section.add "jobIds", valid_593056
  var valid_593057 = formData.getOrDefault("APIVersion")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "APIVersion", valid_593057
  var valid_593058 = formData.getOrDefault("country")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "country", valid_593058
  var valid_593059 = formData.getOrDefault("city")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "city", valid_593059
  var valid_593060 = formData.getOrDefault("street2")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "street2", valid_593060
  var valid_593061 = formData.getOrDefault("company")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "company", valid_593061
  var valid_593062 = formData.getOrDefault("name")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "name", valid_593062
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593063: Call_PostGetShippingLabel_593040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_593063.validator(path, query, header, formData, body)
  let scheme = call_593063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593063.url(scheme.get, call_593063.host, call_593063.base,
                         call_593063.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593063, url, valid)

proc call*(call_593064: Call_PostGetShippingLabel_593040; Signature: string;
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
  var query_593065 = newJObject()
  var formData_593066 = newJObject()
  add(query_593065, "Signature", newJString(Signature))
  add(query_593065, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_593066, "street1", newJString(street1))
  add(query_593065, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593066, "stateOrProvince", newJString(stateOrProvince))
  add(formData_593066, "street3", newJString(street3))
  add(formData_593066, "phoneNumber", newJString(phoneNumber))
  add(formData_593066, "postalCode", newJString(postalCode))
  if jobIds != nil:
    formData_593066.add "jobIds", jobIds
  add(formData_593066, "APIVersion", newJString(APIVersion))
  add(formData_593066, "country", newJString(country))
  add(formData_593066, "city", newJString(city))
  add(formData_593066, "street2", newJString(street2))
  add(query_593065, "Timestamp", newJString(Timestamp))
  add(query_593065, "Action", newJString(Action))
  add(query_593065, "Operation", newJString(Operation))
  add(formData_593066, "company", newJString(company))
  add(query_593065, "Version", newJString(Version))
  add(query_593065, "SignatureVersion", newJString(SignatureVersion))
  add(formData_593066, "name", newJString(name))
  result = call_593064.call(nil, query_593065, nil, formData_593066, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_593040(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_593041, base: "/",
    url: url_PostGetShippingLabel_593042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_593014 = ref object of OpenApiRestCall_592348
proc url_GetGetShippingLabel_593016(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetShippingLabel_593015(path: JsonNode; query: JsonNode;
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
  var valid_593017 = query.getOrDefault("Signature")
  valid_593017 = validateParameter(valid_593017, JString, required = true,
                                 default = nil)
  if valid_593017 != nil:
    section.add "Signature", valid_593017
  var valid_593018 = query.getOrDefault("name")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "name", valid_593018
  var valid_593019 = query.getOrDefault("street2")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "street2", valid_593019
  var valid_593020 = query.getOrDefault("street3")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "street3", valid_593020
  var valid_593021 = query.getOrDefault("AWSAccessKeyId")
  valid_593021 = validateParameter(valid_593021, JString, required = true,
                                 default = nil)
  if valid_593021 != nil:
    section.add "AWSAccessKeyId", valid_593021
  var valid_593022 = query.getOrDefault("SignatureMethod")
  valid_593022 = validateParameter(valid_593022, JString, required = true,
                                 default = nil)
  if valid_593022 != nil:
    section.add "SignatureMethod", valid_593022
  var valid_593023 = query.getOrDefault("phoneNumber")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "phoneNumber", valid_593023
  var valid_593024 = query.getOrDefault("postalCode")
  valid_593024 = validateParameter(valid_593024, JString, required = false,
                                 default = nil)
  if valid_593024 != nil:
    section.add "postalCode", valid_593024
  var valid_593025 = query.getOrDefault("street1")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "street1", valid_593025
  var valid_593026 = query.getOrDefault("city")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "city", valid_593026
  var valid_593027 = query.getOrDefault("country")
  valid_593027 = validateParameter(valid_593027, JString, required = false,
                                 default = nil)
  if valid_593027 != nil:
    section.add "country", valid_593027
  var valid_593028 = query.getOrDefault("Timestamp")
  valid_593028 = validateParameter(valid_593028, JString, required = true,
                                 default = nil)
  if valid_593028 != nil:
    section.add "Timestamp", valid_593028
  var valid_593029 = query.getOrDefault("Action")
  valid_593029 = validateParameter(valid_593029, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_593029 != nil:
    section.add "Action", valid_593029
  var valid_593030 = query.getOrDefault("jobIds")
  valid_593030 = validateParameter(valid_593030, JArray, required = true, default = nil)
  if valid_593030 != nil:
    section.add "jobIds", valid_593030
  var valid_593031 = query.getOrDefault("Operation")
  valid_593031 = validateParameter(valid_593031, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_593031 != nil:
    section.add "Operation", valid_593031
  var valid_593032 = query.getOrDefault("APIVersion")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "APIVersion", valid_593032
  var valid_593033 = query.getOrDefault("Version")
  valid_593033 = validateParameter(valid_593033, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593033 != nil:
    section.add "Version", valid_593033
  var valid_593034 = query.getOrDefault("stateOrProvince")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "stateOrProvince", valid_593034
  var valid_593035 = query.getOrDefault("SignatureVersion")
  valid_593035 = validateParameter(valid_593035, JString, required = true,
                                 default = nil)
  if valid_593035 != nil:
    section.add "SignatureVersion", valid_593035
  var valid_593036 = query.getOrDefault("company")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "company", valid_593036
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593037: Call_GetGetShippingLabel_593014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_593037.validator(path, query, header, formData, body)
  let scheme = call_593037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593037.url(scheme.get, call_593037.host, call_593037.base,
                         call_593037.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593037, url, valid)

proc call*(call_593038: Call_GetGetShippingLabel_593014; Signature: string;
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
  var query_593039 = newJObject()
  add(query_593039, "Signature", newJString(Signature))
  add(query_593039, "name", newJString(name))
  add(query_593039, "street2", newJString(street2))
  add(query_593039, "street3", newJString(street3))
  add(query_593039, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593039, "SignatureMethod", newJString(SignatureMethod))
  add(query_593039, "phoneNumber", newJString(phoneNumber))
  add(query_593039, "postalCode", newJString(postalCode))
  add(query_593039, "street1", newJString(street1))
  add(query_593039, "city", newJString(city))
  add(query_593039, "country", newJString(country))
  add(query_593039, "Timestamp", newJString(Timestamp))
  add(query_593039, "Action", newJString(Action))
  if jobIds != nil:
    query_593039.add "jobIds", jobIds
  add(query_593039, "Operation", newJString(Operation))
  add(query_593039, "APIVersion", newJString(APIVersion))
  add(query_593039, "Version", newJString(Version))
  add(query_593039, "stateOrProvince", newJString(stateOrProvince))
  add(query_593039, "SignatureVersion", newJString(SignatureVersion))
  add(query_593039, "company", newJString(company))
  result = call_593038.call(nil, query_593039, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_593014(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_593015, base: "/",
    url: url_GetGetShippingLabel_593016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_593083 = ref object of OpenApiRestCall_592348
proc url_PostGetStatus_593085(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetStatus_593084(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593086 = query.getOrDefault("Signature")
  valid_593086 = validateParameter(valid_593086, JString, required = true,
                                 default = nil)
  if valid_593086 != nil:
    section.add "Signature", valid_593086
  var valid_593087 = query.getOrDefault("AWSAccessKeyId")
  valid_593087 = validateParameter(valid_593087, JString, required = true,
                                 default = nil)
  if valid_593087 != nil:
    section.add "AWSAccessKeyId", valid_593087
  var valid_593088 = query.getOrDefault("SignatureMethod")
  valid_593088 = validateParameter(valid_593088, JString, required = true,
                                 default = nil)
  if valid_593088 != nil:
    section.add "SignatureMethod", valid_593088
  var valid_593089 = query.getOrDefault("Timestamp")
  valid_593089 = validateParameter(valid_593089, JString, required = true,
                                 default = nil)
  if valid_593089 != nil:
    section.add "Timestamp", valid_593089
  var valid_593090 = query.getOrDefault("Action")
  valid_593090 = validateParameter(valid_593090, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_593090 != nil:
    section.add "Action", valid_593090
  var valid_593091 = query.getOrDefault("Operation")
  valid_593091 = validateParameter(valid_593091, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_593091 != nil:
    section.add "Operation", valid_593091
  var valid_593092 = query.getOrDefault("Version")
  valid_593092 = validateParameter(valid_593092, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593092 != nil:
    section.add "Version", valid_593092
  var valid_593093 = query.getOrDefault("SignatureVersion")
  valid_593093 = validateParameter(valid_593093, JString, required = true,
                                 default = nil)
  if valid_593093 != nil:
    section.add "SignatureVersion", valid_593093
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_593094 = formData.getOrDefault("APIVersion")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "APIVersion", valid_593094
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_593095 = formData.getOrDefault("JobId")
  valid_593095 = validateParameter(valid_593095, JString, required = true,
                                 default = nil)
  if valid_593095 != nil:
    section.add "JobId", valid_593095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593096: Call_PostGetStatus_593083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_593096.validator(path, query, header, formData, body)
  let scheme = call_593096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593096.url(scheme.get, call_593096.host, call_593096.base,
                         call_593096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593096, url, valid)

proc call*(call_593097: Call_PostGetStatus_593083; Signature: string;
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
  var query_593098 = newJObject()
  var formData_593099 = newJObject()
  add(query_593098, "Signature", newJString(Signature))
  add(query_593098, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593098, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593099, "APIVersion", newJString(APIVersion))
  add(query_593098, "Timestamp", newJString(Timestamp))
  add(query_593098, "Action", newJString(Action))
  add(query_593098, "Operation", newJString(Operation))
  add(formData_593099, "JobId", newJString(JobId))
  add(query_593098, "Version", newJString(Version))
  add(query_593098, "SignatureVersion", newJString(SignatureVersion))
  result = call_593097.call(nil, query_593098, nil, formData_593099, nil)

var postGetStatus* = Call_PostGetStatus_593083(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_593084, base: "/", url: url_PostGetStatus_593085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_593067 = ref object of OpenApiRestCall_592348
proc url_GetGetStatus_593069(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetStatus_593068(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593070 = query.getOrDefault("Signature")
  valid_593070 = validateParameter(valid_593070, JString, required = true,
                                 default = nil)
  if valid_593070 != nil:
    section.add "Signature", valid_593070
  var valid_593071 = query.getOrDefault("AWSAccessKeyId")
  valid_593071 = validateParameter(valid_593071, JString, required = true,
                                 default = nil)
  if valid_593071 != nil:
    section.add "AWSAccessKeyId", valid_593071
  var valid_593072 = query.getOrDefault("SignatureMethod")
  valid_593072 = validateParameter(valid_593072, JString, required = true,
                                 default = nil)
  if valid_593072 != nil:
    section.add "SignatureMethod", valid_593072
  var valid_593073 = query.getOrDefault("Timestamp")
  valid_593073 = validateParameter(valid_593073, JString, required = true,
                                 default = nil)
  if valid_593073 != nil:
    section.add "Timestamp", valid_593073
  var valid_593074 = query.getOrDefault("Action")
  valid_593074 = validateParameter(valid_593074, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_593074 != nil:
    section.add "Action", valid_593074
  var valid_593075 = query.getOrDefault("Operation")
  valid_593075 = validateParameter(valid_593075, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_593075 != nil:
    section.add "Operation", valid_593075
  var valid_593076 = query.getOrDefault("APIVersion")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "APIVersion", valid_593076
  var valid_593077 = query.getOrDefault("Version")
  valid_593077 = validateParameter(valid_593077, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593077 != nil:
    section.add "Version", valid_593077
  var valid_593078 = query.getOrDefault("JobId")
  valid_593078 = validateParameter(valid_593078, JString, required = true,
                                 default = nil)
  if valid_593078 != nil:
    section.add "JobId", valid_593078
  var valid_593079 = query.getOrDefault("SignatureVersion")
  valid_593079 = validateParameter(valid_593079, JString, required = true,
                                 default = nil)
  if valid_593079 != nil:
    section.add "SignatureVersion", valid_593079
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593080: Call_GetGetStatus_593067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_593080.validator(path, query, header, formData, body)
  let scheme = call_593080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593080.url(scheme.get, call_593080.host, call_593080.base,
                         call_593080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593080, url, valid)

proc call*(call_593081: Call_GetGetStatus_593067; Signature: string;
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
  var query_593082 = newJObject()
  add(query_593082, "Signature", newJString(Signature))
  add(query_593082, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593082, "SignatureMethod", newJString(SignatureMethod))
  add(query_593082, "Timestamp", newJString(Timestamp))
  add(query_593082, "Action", newJString(Action))
  add(query_593082, "Operation", newJString(Operation))
  add(query_593082, "APIVersion", newJString(APIVersion))
  add(query_593082, "Version", newJString(Version))
  add(query_593082, "JobId", newJString(JobId))
  add(query_593082, "SignatureVersion", newJString(SignatureVersion))
  result = call_593081.call(nil, query_593082, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_593067(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_593068, base: "/", url: url_GetGetStatus_593069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_593117 = ref object of OpenApiRestCall_592348
proc url_PostListJobs_593119(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListJobs_593118(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593120 = query.getOrDefault("Signature")
  valid_593120 = validateParameter(valid_593120, JString, required = true,
                                 default = nil)
  if valid_593120 != nil:
    section.add "Signature", valid_593120
  var valid_593121 = query.getOrDefault("AWSAccessKeyId")
  valid_593121 = validateParameter(valid_593121, JString, required = true,
                                 default = nil)
  if valid_593121 != nil:
    section.add "AWSAccessKeyId", valid_593121
  var valid_593122 = query.getOrDefault("SignatureMethod")
  valid_593122 = validateParameter(valid_593122, JString, required = true,
                                 default = nil)
  if valid_593122 != nil:
    section.add "SignatureMethod", valid_593122
  var valid_593123 = query.getOrDefault("Timestamp")
  valid_593123 = validateParameter(valid_593123, JString, required = true,
                                 default = nil)
  if valid_593123 != nil:
    section.add "Timestamp", valid_593123
  var valid_593124 = query.getOrDefault("Action")
  valid_593124 = validateParameter(valid_593124, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_593124 != nil:
    section.add "Action", valid_593124
  var valid_593125 = query.getOrDefault("Operation")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_593125 != nil:
    section.add "Operation", valid_593125
  var valid_593126 = query.getOrDefault("Version")
  valid_593126 = validateParameter(valid_593126, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593126 != nil:
    section.add "Version", valid_593126
  var valid_593127 = query.getOrDefault("SignatureVersion")
  valid_593127 = validateParameter(valid_593127, JString, required = true,
                                 default = nil)
  if valid_593127 != nil:
    section.add "SignatureVersion", valid_593127
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
  var valid_593128 = formData.getOrDefault("MaxJobs")
  valid_593128 = validateParameter(valid_593128, JInt, required = false, default = nil)
  if valid_593128 != nil:
    section.add "MaxJobs", valid_593128
  var valid_593129 = formData.getOrDefault("Marker")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "Marker", valid_593129
  var valid_593130 = formData.getOrDefault("APIVersion")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "APIVersion", valid_593130
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593131: Call_PostListJobs_593117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_593131.validator(path, query, header, formData, body)
  let scheme = call_593131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593131.url(scheme.get, call_593131.host, call_593131.base,
                         call_593131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593131, url, valid)

proc call*(call_593132: Call_PostListJobs_593117; Signature: string;
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
  var query_593133 = newJObject()
  var formData_593134 = newJObject()
  add(query_593133, "Signature", newJString(Signature))
  add(formData_593134, "MaxJobs", newJInt(MaxJobs))
  add(query_593133, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593133, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593134, "Marker", newJString(Marker))
  add(formData_593134, "APIVersion", newJString(APIVersion))
  add(query_593133, "Timestamp", newJString(Timestamp))
  add(query_593133, "Action", newJString(Action))
  add(query_593133, "Operation", newJString(Operation))
  add(query_593133, "Version", newJString(Version))
  add(query_593133, "SignatureVersion", newJString(SignatureVersion))
  result = call_593132.call(nil, query_593133, nil, formData_593134, nil)

var postListJobs* = Call_PostListJobs_593117(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_593118, base: "/", url: url_PostListJobs_593119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_593100 = ref object of OpenApiRestCall_592348
proc url_GetListJobs_593102(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListJobs_593101(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593103 = query.getOrDefault("MaxJobs")
  valid_593103 = validateParameter(valid_593103, JInt, required = false, default = nil)
  if valid_593103 != nil:
    section.add "MaxJobs", valid_593103
  var valid_593104 = query.getOrDefault("Marker")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "Marker", valid_593104
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_593105 = query.getOrDefault("Signature")
  valid_593105 = validateParameter(valid_593105, JString, required = true,
                                 default = nil)
  if valid_593105 != nil:
    section.add "Signature", valid_593105
  var valid_593106 = query.getOrDefault("AWSAccessKeyId")
  valid_593106 = validateParameter(valid_593106, JString, required = true,
                                 default = nil)
  if valid_593106 != nil:
    section.add "AWSAccessKeyId", valid_593106
  var valid_593107 = query.getOrDefault("SignatureMethod")
  valid_593107 = validateParameter(valid_593107, JString, required = true,
                                 default = nil)
  if valid_593107 != nil:
    section.add "SignatureMethod", valid_593107
  var valid_593108 = query.getOrDefault("Timestamp")
  valid_593108 = validateParameter(valid_593108, JString, required = true,
                                 default = nil)
  if valid_593108 != nil:
    section.add "Timestamp", valid_593108
  var valid_593109 = query.getOrDefault("Action")
  valid_593109 = validateParameter(valid_593109, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_593109 != nil:
    section.add "Action", valid_593109
  var valid_593110 = query.getOrDefault("Operation")
  valid_593110 = validateParameter(valid_593110, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_593110 != nil:
    section.add "Operation", valid_593110
  var valid_593111 = query.getOrDefault("APIVersion")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "APIVersion", valid_593111
  var valid_593112 = query.getOrDefault("Version")
  valid_593112 = validateParameter(valid_593112, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593112 != nil:
    section.add "Version", valid_593112
  var valid_593113 = query.getOrDefault("SignatureVersion")
  valid_593113 = validateParameter(valid_593113, JString, required = true,
                                 default = nil)
  if valid_593113 != nil:
    section.add "SignatureVersion", valid_593113
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593114: Call_GetListJobs_593100; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_593114.validator(path, query, header, formData, body)
  let scheme = call_593114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593114.url(scheme.get, call_593114.host, call_593114.base,
                         call_593114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593114, url, valid)

proc call*(call_593115: Call_GetListJobs_593100; Signature: string;
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
  var query_593116 = newJObject()
  add(query_593116, "MaxJobs", newJInt(MaxJobs))
  add(query_593116, "Marker", newJString(Marker))
  add(query_593116, "Signature", newJString(Signature))
  add(query_593116, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593116, "SignatureMethod", newJString(SignatureMethod))
  add(query_593116, "Timestamp", newJString(Timestamp))
  add(query_593116, "Action", newJString(Action))
  add(query_593116, "Operation", newJString(Operation))
  add(query_593116, "APIVersion", newJString(APIVersion))
  add(query_593116, "Version", newJString(Version))
  add(query_593116, "SignatureVersion", newJString(SignatureVersion))
  result = call_593115.call(nil, query_593116, nil, nil, nil)

var getListJobs* = Call_GetListJobs_593100(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_593101,
                                        base: "/", url: url_GetListJobs_593102,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_593154 = ref object of OpenApiRestCall_592348
proc url_PostUpdateJob_593156(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateJob_593155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593157 = query.getOrDefault("Signature")
  valid_593157 = validateParameter(valid_593157, JString, required = true,
                                 default = nil)
  if valid_593157 != nil:
    section.add "Signature", valid_593157
  var valid_593158 = query.getOrDefault("AWSAccessKeyId")
  valid_593158 = validateParameter(valid_593158, JString, required = true,
                                 default = nil)
  if valid_593158 != nil:
    section.add "AWSAccessKeyId", valid_593158
  var valid_593159 = query.getOrDefault("SignatureMethod")
  valid_593159 = validateParameter(valid_593159, JString, required = true,
                                 default = nil)
  if valid_593159 != nil:
    section.add "SignatureMethod", valid_593159
  var valid_593160 = query.getOrDefault("Timestamp")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = nil)
  if valid_593160 != nil:
    section.add "Timestamp", valid_593160
  var valid_593161 = query.getOrDefault("Action")
  valid_593161 = validateParameter(valid_593161, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_593161 != nil:
    section.add "Action", valid_593161
  var valid_593162 = query.getOrDefault("Operation")
  valid_593162 = validateParameter(valid_593162, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_593162 != nil:
    section.add "Operation", valid_593162
  var valid_593163 = query.getOrDefault("Version")
  valid_593163 = validateParameter(valid_593163, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593163 != nil:
    section.add "Version", valid_593163
  var valid_593164 = query.getOrDefault("SignatureVersion")
  valid_593164 = validateParameter(valid_593164, JString, required = true,
                                 default = nil)
  if valid_593164 != nil:
    section.add "SignatureVersion", valid_593164
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
  var valid_593165 = formData.getOrDefault("ValidateOnly")
  valid_593165 = validateParameter(valid_593165, JBool, required = true, default = nil)
  if valid_593165 != nil:
    section.add "ValidateOnly", valid_593165
  var valid_593166 = formData.getOrDefault("APIVersion")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "APIVersion", valid_593166
  var valid_593167 = formData.getOrDefault("JobId")
  valid_593167 = validateParameter(valid_593167, JString, required = true,
                                 default = nil)
  if valid_593167 != nil:
    section.add "JobId", valid_593167
  var valid_593168 = formData.getOrDefault("JobType")
  valid_593168 = validateParameter(valid_593168, JString, required = true,
                                 default = newJString("Import"))
  if valid_593168 != nil:
    section.add "JobType", valid_593168
  var valid_593169 = formData.getOrDefault("Manifest")
  valid_593169 = validateParameter(valid_593169, JString, required = true,
                                 default = nil)
  if valid_593169 != nil:
    section.add "Manifest", valid_593169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593170: Call_PostUpdateJob_593154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_593170.validator(path, query, header, formData, body)
  let scheme = call_593170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593170.url(scheme.get, call_593170.host, call_593170.base,
                         call_593170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593170, url, valid)

proc call*(call_593171: Call_PostUpdateJob_593154; Signature: string;
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
  var query_593172 = newJObject()
  var formData_593173 = newJObject()
  add(query_593172, "Signature", newJString(Signature))
  add(query_593172, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593172, "SignatureMethod", newJString(SignatureMethod))
  add(formData_593173, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_593173, "APIVersion", newJString(APIVersion))
  add(query_593172, "Timestamp", newJString(Timestamp))
  add(query_593172, "Action", newJString(Action))
  add(query_593172, "Operation", newJString(Operation))
  add(formData_593173, "JobId", newJString(JobId))
  add(query_593172, "Version", newJString(Version))
  add(formData_593173, "JobType", newJString(JobType))
  add(query_593172, "SignatureVersion", newJString(SignatureVersion))
  add(formData_593173, "Manifest", newJString(Manifest))
  result = call_593171.call(nil, query_593172, nil, formData_593173, nil)

var postUpdateJob* = Call_PostUpdateJob_593154(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_593155, base: "/", url: url_PostUpdateJob_593156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_593135 = ref object of OpenApiRestCall_592348
proc url_GetUpdateJob_593137(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateJob_593136(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593138 = query.getOrDefault("Signature")
  valid_593138 = validateParameter(valid_593138, JString, required = true,
                                 default = nil)
  if valid_593138 != nil:
    section.add "Signature", valid_593138
  var valid_593139 = query.getOrDefault("JobType")
  valid_593139 = validateParameter(valid_593139, JString, required = true,
                                 default = newJString("Import"))
  if valid_593139 != nil:
    section.add "JobType", valid_593139
  var valid_593140 = query.getOrDefault("AWSAccessKeyId")
  valid_593140 = validateParameter(valid_593140, JString, required = true,
                                 default = nil)
  if valid_593140 != nil:
    section.add "AWSAccessKeyId", valid_593140
  var valid_593141 = query.getOrDefault("SignatureMethod")
  valid_593141 = validateParameter(valid_593141, JString, required = true,
                                 default = nil)
  if valid_593141 != nil:
    section.add "SignatureMethod", valid_593141
  var valid_593142 = query.getOrDefault("Manifest")
  valid_593142 = validateParameter(valid_593142, JString, required = true,
                                 default = nil)
  if valid_593142 != nil:
    section.add "Manifest", valid_593142
  var valid_593143 = query.getOrDefault("ValidateOnly")
  valid_593143 = validateParameter(valid_593143, JBool, required = true, default = nil)
  if valid_593143 != nil:
    section.add "ValidateOnly", valid_593143
  var valid_593144 = query.getOrDefault("Timestamp")
  valid_593144 = validateParameter(valid_593144, JString, required = true,
                                 default = nil)
  if valid_593144 != nil:
    section.add "Timestamp", valid_593144
  var valid_593145 = query.getOrDefault("Action")
  valid_593145 = validateParameter(valid_593145, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_593145 != nil:
    section.add "Action", valid_593145
  var valid_593146 = query.getOrDefault("Operation")
  valid_593146 = validateParameter(valid_593146, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_593146 != nil:
    section.add "Operation", valid_593146
  var valid_593147 = query.getOrDefault("APIVersion")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "APIVersion", valid_593147
  var valid_593148 = query.getOrDefault("Version")
  valid_593148 = validateParameter(valid_593148, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593148 != nil:
    section.add "Version", valid_593148
  var valid_593149 = query.getOrDefault("JobId")
  valid_593149 = validateParameter(valid_593149, JString, required = true,
                                 default = nil)
  if valid_593149 != nil:
    section.add "JobId", valid_593149
  var valid_593150 = query.getOrDefault("SignatureVersion")
  valid_593150 = validateParameter(valid_593150, JString, required = true,
                                 default = nil)
  if valid_593150 != nil:
    section.add "SignatureVersion", valid_593150
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593151: Call_GetUpdateJob_593135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_593151.validator(path, query, header, formData, body)
  let scheme = call_593151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593151.url(scheme.get, call_593151.host, call_593151.base,
                         call_593151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593151, url, valid)

proc call*(call_593152: Call_GetUpdateJob_593135; Signature: string;
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
  var query_593153 = newJObject()
  add(query_593153, "Signature", newJString(Signature))
  add(query_593153, "JobType", newJString(JobType))
  add(query_593153, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593153, "SignatureMethod", newJString(SignatureMethod))
  add(query_593153, "Manifest", newJString(Manifest))
  add(query_593153, "ValidateOnly", newJBool(ValidateOnly))
  add(query_593153, "Timestamp", newJString(Timestamp))
  add(query_593153, "Action", newJString(Action))
  add(query_593153, "Operation", newJString(Operation))
  add(query_593153, "APIVersion", newJString(APIVersion))
  add(query_593153, "Version", newJString(Version))
  add(query_593153, "JobId", newJString(JobId))
  add(query_593153, "SignatureVersion", newJString(SignatureVersion))
  result = call_593152.call(nil, query_593153, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_593135(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_593136, base: "/", url: url_GetUpdateJob_593137,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
