
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

  OpenApiRestCall_601373 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601373](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601373): Option[Scheme] {.used.} =
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
  Call_PostCancelJob_601982 = ref object of OpenApiRestCall_601373
proc url_PostCancelJob_601984(protocol: Scheme; host: string; base: string;
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

proc validate_PostCancelJob_601983(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601985 = query.getOrDefault("Signature")
  valid_601985 = validateParameter(valid_601985, JString, required = true,
                                 default = nil)
  if valid_601985 != nil:
    section.add "Signature", valid_601985
  var valid_601986 = query.getOrDefault("AWSAccessKeyId")
  valid_601986 = validateParameter(valid_601986, JString, required = true,
                                 default = nil)
  if valid_601986 != nil:
    section.add "AWSAccessKeyId", valid_601986
  var valid_601987 = query.getOrDefault("SignatureMethod")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = nil)
  if valid_601987 != nil:
    section.add "SignatureMethod", valid_601987
  var valid_601988 = query.getOrDefault("Timestamp")
  valid_601988 = validateParameter(valid_601988, JString, required = true,
                                 default = nil)
  if valid_601988 != nil:
    section.add "Timestamp", valid_601988
  var valid_601989 = query.getOrDefault("Action")
  valid_601989 = validateParameter(valid_601989, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601989 != nil:
    section.add "Action", valid_601989
  var valid_601990 = query.getOrDefault("Operation")
  valid_601990 = validateParameter(valid_601990, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601990 != nil:
    section.add "Operation", valid_601990
  var valid_601991 = query.getOrDefault("Version")
  valid_601991 = validateParameter(valid_601991, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601991 != nil:
    section.add "Version", valid_601991
  var valid_601992 = query.getOrDefault("SignatureVersion")
  valid_601992 = validateParameter(valid_601992, JString, required = true,
                                 default = nil)
  if valid_601992 != nil:
    section.add "SignatureVersion", valid_601992
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_601993 = formData.getOrDefault("APIVersion")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "APIVersion", valid_601993
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_601994 = formData.getOrDefault("JobId")
  valid_601994 = validateParameter(valid_601994, JString, required = true,
                                 default = nil)
  if valid_601994 != nil:
    section.add "JobId", valid_601994
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_PostCancelJob_601982; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_PostCancelJob_601982; Signature: string;
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
  var query_601997 = newJObject()
  var formData_601998 = newJObject()
  add(query_601997, "Signature", newJString(Signature))
  add(query_601997, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601997, "SignatureMethod", newJString(SignatureMethod))
  add(formData_601998, "APIVersion", newJString(APIVersion))
  add(query_601997, "Timestamp", newJString(Timestamp))
  add(query_601997, "Action", newJString(Action))
  add(query_601997, "Operation", newJString(Operation))
  add(formData_601998, "JobId", newJString(JobId))
  add(query_601997, "Version", newJString(Version))
  add(query_601997, "SignatureVersion", newJString(SignatureVersion))
  result = call_601996.call(nil, query_601997, nil, formData_601998, nil)

var postCancelJob* = Call_PostCancelJob_601982(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_601983, base: "/", url: url_PostCancelJob_601984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_601711 = ref object of OpenApiRestCall_601373
proc url_GetCancelJob_601713(protocol: Scheme; host: string; base: string;
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

proc validate_GetCancelJob_601712(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601825 = query.getOrDefault("Signature")
  valid_601825 = validateParameter(valid_601825, JString, required = true,
                                 default = nil)
  if valid_601825 != nil:
    section.add "Signature", valid_601825
  var valid_601826 = query.getOrDefault("AWSAccessKeyId")
  valid_601826 = validateParameter(valid_601826, JString, required = true,
                                 default = nil)
  if valid_601826 != nil:
    section.add "AWSAccessKeyId", valid_601826
  var valid_601827 = query.getOrDefault("SignatureMethod")
  valid_601827 = validateParameter(valid_601827, JString, required = true,
                                 default = nil)
  if valid_601827 != nil:
    section.add "SignatureMethod", valid_601827
  var valid_601828 = query.getOrDefault("Timestamp")
  valid_601828 = validateParameter(valid_601828, JString, required = true,
                                 default = nil)
  if valid_601828 != nil:
    section.add "Timestamp", valid_601828
  var valid_601842 = query.getOrDefault("Action")
  valid_601842 = validateParameter(valid_601842, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601842 != nil:
    section.add "Action", valid_601842
  var valid_601843 = query.getOrDefault("Operation")
  valid_601843 = validateParameter(valid_601843, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_601843 != nil:
    section.add "Operation", valid_601843
  var valid_601844 = query.getOrDefault("APIVersion")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "APIVersion", valid_601844
  var valid_601845 = query.getOrDefault("Version")
  valid_601845 = validateParameter(valid_601845, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_601845 != nil:
    section.add "Version", valid_601845
  var valid_601846 = query.getOrDefault("JobId")
  valid_601846 = validateParameter(valid_601846, JString, required = true,
                                 default = nil)
  if valid_601846 != nil:
    section.add "JobId", valid_601846
  var valid_601847 = query.getOrDefault("SignatureVersion")
  valid_601847 = validateParameter(valid_601847, JString, required = true,
                                 default = nil)
  if valid_601847 != nil:
    section.add "SignatureVersion", valid_601847
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601870: Call_GetCancelJob_601711; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_601870.validator(path, query, header, formData, body)
  let scheme = call_601870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601870.url(scheme.get, call_601870.host, call_601870.base,
                         call_601870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601870, url, valid)

proc call*(call_601941: Call_GetCancelJob_601711; Signature: string;
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
  var query_601942 = newJObject()
  add(query_601942, "Signature", newJString(Signature))
  add(query_601942, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_601942, "SignatureMethod", newJString(SignatureMethod))
  add(query_601942, "Timestamp", newJString(Timestamp))
  add(query_601942, "Action", newJString(Action))
  add(query_601942, "Operation", newJString(Operation))
  add(query_601942, "APIVersion", newJString(APIVersion))
  add(query_601942, "Version", newJString(Version))
  add(query_601942, "JobId", newJString(JobId))
  add(query_601942, "SignatureVersion", newJString(SignatureVersion))
  result = call_601941.call(nil, query_601942, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_601711(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_601712, base: "/", url: url_GetCancelJob_601713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_602018 = ref object of OpenApiRestCall_601373
proc url_PostCreateJob_602020(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateJob_602019(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602021 = query.getOrDefault("Signature")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = nil)
  if valid_602021 != nil:
    section.add "Signature", valid_602021
  var valid_602022 = query.getOrDefault("AWSAccessKeyId")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = nil)
  if valid_602022 != nil:
    section.add "AWSAccessKeyId", valid_602022
  var valid_602023 = query.getOrDefault("SignatureMethod")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = nil)
  if valid_602023 != nil:
    section.add "SignatureMethod", valid_602023
  var valid_602024 = query.getOrDefault("Timestamp")
  valid_602024 = validateParameter(valid_602024, JString, required = true,
                                 default = nil)
  if valid_602024 != nil:
    section.add "Timestamp", valid_602024
  var valid_602025 = query.getOrDefault("Action")
  valid_602025 = validateParameter(valid_602025, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_602025 != nil:
    section.add "Action", valid_602025
  var valid_602026 = query.getOrDefault("Operation")
  valid_602026 = validateParameter(valid_602026, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_602026 != nil:
    section.add "Operation", valid_602026
  var valid_602027 = query.getOrDefault("Version")
  valid_602027 = validateParameter(valid_602027, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602027 != nil:
    section.add "Version", valid_602027
  var valid_602028 = query.getOrDefault("SignatureVersion")
  valid_602028 = validateParameter(valid_602028, JString, required = true,
                                 default = nil)
  if valid_602028 != nil:
    section.add "SignatureVersion", valid_602028
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
  var valid_602029 = formData.getOrDefault("ValidateOnly")
  valid_602029 = validateParameter(valid_602029, JBool, required = true, default = nil)
  if valid_602029 != nil:
    section.add "ValidateOnly", valid_602029
  var valid_602030 = formData.getOrDefault("APIVersion")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "APIVersion", valid_602030
  var valid_602031 = formData.getOrDefault("ManifestAddendum")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "ManifestAddendum", valid_602031
  var valid_602032 = formData.getOrDefault("JobType")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = newJString("Import"))
  if valid_602032 != nil:
    section.add "JobType", valid_602032
  var valid_602033 = formData.getOrDefault("Manifest")
  valid_602033 = validateParameter(valid_602033, JString, required = true,
                                 default = nil)
  if valid_602033 != nil:
    section.add "Manifest", valid_602033
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602034: Call_PostCreateJob_602018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_602034.validator(path, query, header, formData, body)
  let scheme = call_602034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602034.url(scheme.get, call_602034.host, call_602034.base,
                         call_602034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602034, url, valid)

proc call*(call_602035: Call_PostCreateJob_602018; Signature: string;
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
  var query_602036 = newJObject()
  var formData_602037 = newJObject()
  add(query_602036, "Signature", newJString(Signature))
  add(query_602036, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602036, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602037, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_602037, "APIVersion", newJString(APIVersion))
  add(query_602036, "Timestamp", newJString(Timestamp))
  add(query_602036, "Action", newJString(Action))
  add(formData_602037, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_602036, "Operation", newJString(Operation))
  add(query_602036, "Version", newJString(Version))
  add(formData_602037, "JobType", newJString(JobType))
  add(query_602036, "SignatureVersion", newJString(SignatureVersion))
  add(formData_602037, "Manifest", newJString(Manifest))
  result = call_602035.call(nil, query_602036, nil, formData_602037, nil)

var postCreateJob* = Call_PostCreateJob_602018(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_602019, base: "/", url: url_PostCreateJob_602020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_601999 = ref object of OpenApiRestCall_601373
proc url_GetCreateJob_602001(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateJob_602000(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602002 = query.getOrDefault("Signature")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = nil)
  if valid_602002 != nil:
    section.add "Signature", valid_602002
  var valid_602003 = query.getOrDefault("JobType")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = newJString("Import"))
  if valid_602003 != nil:
    section.add "JobType", valid_602003
  var valid_602004 = query.getOrDefault("AWSAccessKeyId")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = nil)
  if valid_602004 != nil:
    section.add "AWSAccessKeyId", valid_602004
  var valid_602005 = query.getOrDefault("SignatureMethod")
  valid_602005 = validateParameter(valid_602005, JString, required = true,
                                 default = nil)
  if valid_602005 != nil:
    section.add "SignatureMethod", valid_602005
  var valid_602006 = query.getOrDefault("Manifest")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = nil)
  if valid_602006 != nil:
    section.add "Manifest", valid_602006
  var valid_602007 = query.getOrDefault("ValidateOnly")
  valid_602007 = validateParameter(valid_602007, JBool, required = true, default = nil)
  if valid_602007 != nil:
    section.add "ValidateOnly", valid_602007
  var valid_602008 = query.getOrDefault("Timestamp")
  valid_602008 = validateParameter(valid_602008, JString, required = true,
                                 default = nil)
  if valid_602008 != nil:
    section.add "Timestamp", valid_602008
  var valid_602009 = query.getOrDefault("Action")
  valid_602009 = validateParameter(valid_602009, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_602009 != nil:
    section.add "Action", valid_602009
  var valid_602010 = query.getOrDefault("ManifestAddendum")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "ManifestAddendum", valid_602010
  var valid_602011 = query.getOrDefault("Operation")
  valid_602011 = validateParameter(valid_602011, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_602011 != nil:
    section.add "Operation", valid_602011
  var valid_602012 = query.getOrDefault("APIVersion")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "APIVersion", valid_602012
  var valid_602013 = query.getOrDefault("Version")
  valid_602013 = validateParameter(valid_602013, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602013 != nil:
    section.add "Version", valid_602013
  var valid_602014 = query.getOrDefault("SignatureVersion")
  valid_602014 = validateParameter(valid_602014, JString, required = true,
                                 default = nil)
  if valid_602014 != nil:
    section.add "SignatureVersion", valid_602014
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602015: Call_GetCreateJob_601999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_602015.validator(path, query, header, formData, body)
  let scheme = call_602015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602015.url(scheme.get, call_602015.host, call_602015.base,
                         call_602015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602015, url, valid)

proc call*(call_602016: Call_GetCreateJob_601999; Signature: string;
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
  var query_602017 = newJObject()
  add(query_602017, "Signature", newJString(Signature))
  add(query_602017, "JobType", newJString(JobType))
  add(query_602017, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602017, "SignatureMethod", newJString(SignatureMethod))
  add(query_602017, "Manifest", newJString(Manifest))
  add(query_602017, "ValidateOnly", newJBool(ValidateOnly))
  add(query_602017, "Timestamp", newJString(Timestamp))
  add(query_602017, "Action", newJString(Action))
  add(query_602017, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_602017, "Operation", newJString(Operation))
  add(query_602017, "APIVersion", newJString(APIVersion))
  add(query_602017, "Version", newJString(Version))
  add(query_602017, "SignatureVersion", newJString(SignatureVersion))
  result = call_602016.call(nil, query_602017, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_601999(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_602000, base: "/", url: url_GetCreateJob_602001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_602064 = ref object of OpenApiRestCall_601373
proc url_PostGetShippingLabel_602066(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetShippingLabel_602065(path: JsonNode; query: JsonNode;
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
  var valid_602067 = query.getOrDefault("Signature")
  valid_602067 = validateParameter(valid_602067, JString, required = true,
                                 default = nil)
  if valid_602067 != nil:
    section.add "Signature", valid_602067
  var valid_602068 = query.getOrDefault("AWSAccessKeyId")
  valid_602068 = validateParameter(valid_602068, JString, required = true,
                                 default = nil)
  if valid_602068 != nil:
    section.add "AWSAccessKeyId", valid_602068
  var valid_602069 = query.getOrDefault("SignatureMethod")
  valid_602069 = validateParameter(valid_602069, JString, required = true,
                                 default = nil)
  if valid_602069 != nil:
    section.add "SignatureMethod", valid_602069
  var valid_602070 = query.getOrDefault("Timestamp")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = nil)
  if valid_602070 != nil:
    section.add "Timestamp", valid_602070
  var valid_602071 = query.getOrDefault("Action")
  valid_602071 = validateParameter(valid_602071, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_602071 != nil:
    section.add "Action", valid_602071
  var valid_602072 = query.getOrDefault("Operation")
  valid_602072 = validateParameter(valid_602072, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_602072 != nil:
    section.add "Operation", valid_602072
  var valid_602073 = query.getOrDefault("Version")
  valid_602073 = validateParameter(valid_602073, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602073 != nil:
    section.add "Version", valid_602073
  var valid_602074 = query.getOrDefault("SignatureVersion")
  valid_602074 = validateParameter(valid_602074, JString, required = true,
                                 default = nil)
  if valid_602074 != nil:
    section.add "SignatureVersion", valid_602074
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
  var valid_602075 = formData.getOrDefault("street1")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "street1", valid_602075
  var valid_602076 = formData.getOrDefault("stateOrProvince")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "stateOrProvince", valid_602076
  var valid_602077 = formData.getOrDefault("street3")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "street3", valid_602077
  var valid_602078 = formData.getOrDefault("phoneNumber")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "phoneNumber", valid_602078
  var valid_602079 = formData.getOrDefault("postalCode")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "postalCode", valid_602079
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_602080 = formData.getOrDefault("jobIds")
  valid_602080 = validateParameter(valid_602080, JArray, required = true, default = nil)
  if valid_602080 != nil:
    section.add "jobIds", valid_602080
  var valid_602081 = formData.getOrDefault("APIVersion")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "APIVersion", valid_602081
  var valid_602082 = formData.getOrDefault("country")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "country", valid_602082
  var valid_602083 = formData.getOrDefault("city")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "city", valid_602083
  var valid_602084 = formData.getOrDefault("street2")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "street2", valid_602084
  var valid_602085 = formData.getOrDefault("company")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "company", valid_602085
  var valid_602086 = formData.getOrDefault("name")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "name", valid_602086
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602087: Call_PostGetShippingLabel_602064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_602087.validator(path, query, header, formData, body)
  let scheme = call_602087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602087.url(scheme.get, call_602087.host, call_602087.base,
                         call_602087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602087, url, valid)

proc call*(call_602088: Call_PostGetShippingLabel_602064; Signature: string;
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
  var query_602089 = newJObject()
  var formData_602090 = newJObject()
  add(query_602089, "Signature", newJString(Signature))
  add(query_602089, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_602090, "street1", newJString(street1))
  add(query_602089, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602090, "stateOrProvince", newJString(stateOrProvince))
  add(formData_602090, "street3", newJString(street3))
  add(formData_602090, "phoneNumber", newJString(phoneNumber))
  add(formData_602090, "postalCode", newJString(postalCode))
  if jobIds != nil:
    formData_602090.add "jobIds", jobIds
  add(formData_602090, "APIVersion", newJString(APIVersion))
  add(formData_602090, "country", newJString(country))
  add(formData_602090, "city", newJString(city))
  add(formData_602090, "street2", newJString(street2))
  add(query_602089, "Timestamp", newJString(Timestamp))
  add(query_602089, "Action", newJString(Action))
  add(query_602089, "Operation", newJString(Operation))
  add(formData_602090, "company", newJString(company))
  add(query_602089, "Version", newJString(Version))
  add(query_602089, "SignatureVersion", newJString(SignatureVersion))
  add(formData_602090, "name", newJString(name))
  result = call_602088.call(nil, query_602089, nil, formData_602090, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_602064(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_602065, base: "/",
    url: url_PostGetShippingLabel_602066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_602038 = ref object of OpenApiRestCall_601373
proc url_GetGetShippingLabel_602040(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetShippingLabel_602039(path: JsonNode; query: JsonNode;
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
  var valid_602041 = query.getOrDefault("Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = nil)
  if valid_602041 != nil:
    section.add "Signature", valid_602041
  var valid_602042 = query.getOrDefault("name")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "name", valid_602042
  var valid_602043 = query.getOrDefault("street2")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "street2", valid_602043
  var valid_602044 = query.getOrDefault("street3")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "street3", valid_602044
  var valid_602045 = query.getOrDefault("AWSAccessKeyId")
  valid_602045 = validateParameter(valid_602045, JString, required = true,
                                 default = nil)
  if valid_602045 != nil:
    section.add "AWSAccessKeyId", valid_602045
  var valid_602046 = query.getOrDefault("SignatureMethod")
  valid_602046 = validateParameter(valid_602046, JString, required = true,
                                 default = nil)
  if valid_602046 != nil:
    section.add "SignatureMethod", valid_602046
  var valid_602047 = query.getOrDefault("phoneNumber")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "phoneNumber", valid_602047
  var valid_602048 = query.getOrDefault("postalCode")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "postalCode", valid_602048
  var valid_602049 = query.getOrDefault("street1")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "street1", valid_602049
  var valid_602050 = query.getOrDefault("city")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "city", valid_602050
  var valid_602051 = query.getOrDefault("country")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "country", valid_602051
  var valid_602052 = query.getOrDefault("Timestamp")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = nil)
  if valid_602052 != nil:
    section.add "Timestamp", valid_602052
  var valid_602053 = query.getOrDefault("Action")
  valid_602053 = validateParameter(valid_602053, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_602053 != nil:
    section.add "Action", valid_602053
  var valid_602054 = query.getOrDefault("jobIds")
  valid_602054 = validateParameter(valid_602054, JArray, required = true, default = nil)
  if valid_602054 != nil:
    section.add "jobIds", valid_602054
  var valid_602055 = query.getOrDefault("Operation")
  valid_602055 = validateParameter(valid_602055, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_602055 != nil:
    section.add "Operation", valid_602055
  var valid_602056 = query.getOrDefault("APIVersion")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "APIVersion", valid_602056
  var valid_602057 = query.getOrDefault("Version")
  valid_602057 = validateParameter(valid_602057, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602057 != nil:
    section.add "Version", valid_602057
  var valid_602058 = query.getOrDefault("stateOrProvince")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "stateOrProvince", valid_602058
  var valid_602059 = query.getOrDefault("SignatureVersion")
  valid_602059 = validateParameter(valid_602059, JString, required = true,
                                 default = nil)
  if valid_602059 != nil:
    section.add "SignatureVersion", valid_602059
  var valid_602060 = query.getOrDefault("company")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "company", valid_602060
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602061: Call_GetGetShippingLabel_602038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_602061.validator(path, query, header, formData, body)
  let scheme = call_602061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602061.url(scheme.get, call_602061.host, call_602061.base,
                         call_602061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602061, url, valid)

proc call*(call_602062: Call_GetGetShippingLabel_602038; Signature: string;
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
  var query_602063 = newJObject()
  add(query_602063, "Signature", newJString(Signature))
  add(query_602063, "name", newJString(name))
  add(query_602063, "street2", newJString(street2))
  add(query_602063, "street3", newJString(street3))
  add(query_602063, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602063, "SignatureMethod", newJString(SignatureMethod))
  add(query_602063, "phoneNumber", newJString(phoneNumber))
  add(query_602063, "postalCode", newJString(postalCode))
  add(query_602063, "street1", newJString(street1))
  add(query_602063, "city", newJString(city))
  add(query_602063, "country", newJString(country))
  add(query_602063, "Timestamp", newJString(Timestamp))
  add(query_602063, "Action", newJString(Action))
  if jobIds != nil:
    query_602063.add "jobIds", jobIds
  add(query_602063, "Operation", newJString(Operation))
  add(query_602063, "APIVersion", newJString(APIVersion))
  add(query_602063, "Version", newJString(Version))
  add(query_602063, "stateOrProvince", newJString(stateOrProvince))
  add(query_602063, "SignatureVersion", newJString(SignatureVersion))
  add(query_602063, "company", newJString(company))
  result = call_602062.call(nil, query_602063, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_602038(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_602039, base: "/",
    url: url_GetGetShippingLabel_602040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_602107 = ref object of OpenApiRestCall_601373
proc url_PostGetStatus_602109(protocol: Scheme; host: string; base: string;
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

proc validate_PostGetStatus_602108(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602110 = query.getOrDefault("Signature")
  valid_602110 = validateParameter(valid_602110, JString, required = true,
                                 default = nil)
  if valid_602110 != nil:
    section.add "Signature", valid_602110
  var valid_602111 = query.getOrDefault("AWSAccessKeyId")
  valid_602111 = validateParameter(valid_602111, JString, required = true,
                                 default = nil)
  if valid_602111 != nil:
    section.add "AWSAccessKeyId", valid_602111
  var valid_602112 = query.getOrDefault("SignatureMethod")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = nil)
  if valid_602112 != nil:
    section.add "SignatureMethod", valid_602112
  var valid_602113 = query.getOrDefault("Timestamp")
  valid_602113 = validateParameter(valid_602113, JString, required = true,
                                 default = nil)
  if valid_602113 != nil:
    section.add "Timestamp", valid_602113
  var valid_602114 = query.getOrDefault("Action")
  valid_602114 = validateParameter(valid_602114, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_602114 != nil:
    section.add "Action", valid_602114
  var valid_602115 = query.getOrDefault("Operation")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_602115 != nil:
    section.add "Operation", valid_602115
  var valid_602116 = query.getOrDefault("Version")
  valid_602116 = validateParameter(valid_602116, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602116 != nil:
    section.add "Version", valid_602116
  var valid_602117 = query.getOrDefault("SignatureVersion")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = nil)
  if valid_602117 != nil:
    section.add "SignatureVersion", valid_602117
  result.add "query", section
  section = newJObject()
  result.add "header", section
  ## parameters in `formData` object:
  ##   APIVersion: JString
  ##             : Specifies the version of the client tool.
  ##   JobId: JString (required)
  ##        : A unique identifier which refers to a particular job.
  section = newJObject()
  var valid_602118 = formData.getOrDefault("APIVersion")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "APIVersion", valid_602118
  assert formData != nil,
        "formData argument is necessary due to required `JobId` field"
  var valid_602119 = formData.getOrDefault("JobId")
  valid_602119 = validateParameter(valid_602119, JString, required = true,
                                 default = nil)
  if valid_602119 != nil:
    section.add "JobId", valid_602119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602120: Call_PostGetStatus_602107; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_602120.validator(path, query, header, formData, body)
  let scheme = call_602120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602120.url(scheme.get, call_602120.host, call_602120.base,
                         call_602120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602120, url, valid)

proc call*(call_602121: Call_PostGetStatus_602107; Signature: string;
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
  var query_602122 = newJObject()
  var formData_602123 = newJObject()
  add(query_602122, "Signature", newJString(Signature))
  add(query_602122, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602122, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602123, "APIVersion", newJString(APIVersion))
  add(query_602122, "Timestamp", newJString(Timestamp))
  add(query_602122, "Action", newJString(Action))
  add(query_602122, "Operation", newJString(Operation))
  add(formData_602123, "JobId", newJString(JobId))
  add(query_602122, "Version", newJString(Version))
  add(query_602122, "SignatureVersion", newJString(SignatureVersion))
  result = call_602121.call(nil, query_602122, nil, formData_602123, nil)

var postGetStatus* = Call_PostGetStatus_602107(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_602108, base: "/", url: url_PostGetStatus_602109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_602091 = ref object of OpenApiRestCall_601373
proc url_GetGetStatus_602093(protocol: Scheme; host: string; base: string;
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

proc validate_GetGetStatus_602092(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602094 = query.getOrDefault("Signature")
  valid_602094 = validateParameter(valid_602094, JString, required = true,
                                 default = nil)
  if valid_602094 != nil:
    section.add "Signature", valid_602094
  var valid_602095 = query.getOrDefault("AWSAccessKeyId")
  valid_602095 = validateParameter(valid_602095, JString, required = true,
                                 default = nil)
  if valid_602095 != nil:
    section.add "AWSAccessKeyId", valid_602095
  var valid_602096 = query.getOrDefault("SignatureMethod")
  valid_602096 = validateParameter(valid_602096, JString, required = true,
                                 default = nil)
  if valid_602096 != nil:
    section.add "SignatureMethod", valid_602096
  var valid_602097 = query.getOrDefault("Timestamp")
  valid_602097 = validateParameter(valid_602097, JString, required = true,
                                 default = nil)
  if valid_602097 != nil:
    section.add "Timestamp", valid_602097
  var valid_602098 = query.getOrDefault("Action")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_602098 != nil:
    section.add "Action", valid_602098
  var valid_602099 = query.getOrDefault("Operation")
  valid_602099 = validateParameter(valid_602099, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_602099 != nil:
    section.add "Operation", valid_602099
  var valid_602100 = query.getOrDefault("APIVersion")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "APIVersion", valid_602100
  var valid_602101 = query.getOrDefault("Version")
  valid_602101 = validateParameter(valid_602101, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602101 != nil:
    section.add "Version", valid_602101
  var valid_602102 = query.getOrDefault("JobId")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = nil)
  if valid_602102 != nil:
    section.add "JobId", valid_602102
  var valid_602103 = query.getOrDefault("SignatureVersion")
  valid_602103 = validateParameter(valid_602103, JString, required = true,
                                 default = nil)
  if valid_602103 != nil:
    section.add "SignatureVersion", valid_602103
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602104: Call_GetGetStatus_602091; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_602104.validator(path, query, header, formData, body)
  let scheme = call_602104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602104.url(scheme.get, call_602104.host, call_602104.base,
                         call_602104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602104, url, valid)

proc call*(call_602105: Call_GetGetStatus_602091; Signature: string;
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
  var query_602106 = newJObject()
  add(query_602106, "Signature", newJString(Signature))
  add(query_602106, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602106, "SignatureMethod", newJString(SignatureMethod))
  add(query_602106, "Timestamp", newJString(Timestamp))
  add(query_602106, "Action", newJString(Action))
  add(query_602106, "Operation", newJString(Operation))
  add(query_602106, "APIVersion", newJString(APIVersion))
  add(query_602106, "Version", newJString(Version))
  add(query_602106, "JobId", newJString(JobId))
  add(query_602106, "SignatureVersion", newJString(SignatureVersion))
  result = call_602105.call(nil, query_602106, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_602091(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_602092, base: "/", url: url_GetGetStatus_602093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_602141 = ref object of OpenApiRestCall_601373
proc url_PostListJobs_602143(protocol: Scheme; host: string; base: string;
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

proc validate_PostListJobs_602142(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602144 = query.getOrDefault("Signature")
  valid_602144 = validateParameter(valid_602144, JString, required = true,
                                 default = nil)
  if valid_602144 != nil:
    section.add "Signature", valid_602144
  var valid_602145 = query.getOrDefault("AWSAccessKeyId")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = nil)
  if valid_602145 != nil:
    section.add "AWSAccessKeyId", valid_602145
  var valid_602146 = query.getOrDefault("SignatureMethod")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "SignatureMethod", valid_602146
  var valid_602147 = query.getOrDefault("Timestamp")
  valid_602147 = validateParameter(valid_602147, JString, required = true,
                                 default = nil)
  if valid_602147 != nil:
    section.add "Timestamp", valid_602147
  var valid_602148 = query.getOrDefault("Action")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_602148 != nil:
    section.add "Action", valid_602148
  var valid_602149 = query.getOrDefault("Operation")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_602149 != nil:
    section.add "Operation", valid_602149
  var valid_602150 = query.getOrDefault("Version")
  valid_602150 = validateParameter(valid_602150, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602150 != nil:
    section.add "Version", valid_602150
  var valid_602151 = query.getOrDefault("SignatureVersion")
  valid_602151 = validateParameter(valid_602151, JString, required = true,
                                 default = nil)
  if valid_602151 != nil:
    section.add "SignatureVersion", valid_602151
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
  var valid_602152 = formData.getOrDefault("MaxJobs")
  valid_602152 = validateParameter(valid_602152, JInt, required = false, default = nil)
  if valid_602152 != nil:
    section.add "MaxJobs", valid_602152
  var valid_602153 = formData.getOrDefault("Marker")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "Marker", valid_602153
  var valid_602154 = formData.getOrDefault("APIVersion")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "APIVersion", valid_602154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602155: Call_PostListJobs_602141; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_602155.validator(path, query, header, formData, body)
  let scheme = call_602155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602155.url(scheme.get, call_602155.host, call_602155.base,
                         call_602155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602155, url, valid)

proc call*(call_602156: Call_PostListJobs_602141; Signature: string;
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
  var query_602157 = newJObject()
  var formData_602158 = newJObject()
  add(query_602157, "Signature", newJString(Signature))
  add(formData_602158, "MaxJobs", newJInt(MaxJobs))
  add(query_602157, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602157, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602158, "Marker", newJString(Marker))
  add(formData_602158, "APIVersion", newJString(APIVersion))
  add(query_602157, "Timestamp", newJString(Timestamp))
  add(query_602157, "Action", newJString(Action))
  add(query_602157, "Operation", newJString(Operation))
  add(query_602157, "Version", newJString(Version))
  add(query_602157, "SignatureVersion", newJString(SignatureVersion))
  result = call_602156.call(nil, query_602157, nil, formData_602158, nil)

var postListJobs* = Call_PostListJobs_602141(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_602142, base: "/", url: url_PostListJobs_602143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_602124 = ref object of OpenApiRestCall_601373
proc url_GetListJobs_602126(protocol: Scheme; host: string; base: string;
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

proc validate_GetListJobs_602125(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602127 = query.getOrDefault("MaxJobs")
  valid_602127 = validateParameter(valid_602127, JInt, required = false, default = nil)
  if valid_602127 != nil:
    section.add "MaxJobs", valid_602127
  var valid_602128 = query.getOrDefault("Marker")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "Marker", valid_602128
  assert query != nil,
        "query argument is necessary due to required `Signature` field"
  var valid_602129 = query.getOrDefault("Signature")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = nil)
  if valid_602129 != nil:
    section.add "Signature", valid_602129
  var valid_602130 = query.getOrDefault("AWSAccessKeyId")
  valid_602130 = validateParameter(valid_602130, JString, required = true,
                                 default = nil)
  if valid_602130 != nil:
    section.add "AWSAccessKeyId", valid_602130
  var valid_602131 = query.getOrDefault("SignatureMethod")
  valid_602131 = validateParameter(valid_602131, JString, required = true,
                                 default = nil)
  if valid_602131 != nil:
    section.add "SignatureMethod", valid_602131
  var valid_602132 = query.getOrDefault("Timestamp")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = nil)
  if valid_602132 != nil:
    section.add "Timestamp", valid_602132
  var valid_602133 = query.getOrDefault("Action")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_602133 != nil:
    section.add "Action", valid_602133
  var valid_602134 = query.getOrDefault("Operation")
  valid_602134 = validateParameter(valid_602134, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_602134 != nil:
    section.add "Operation", valid_602134
  var valid_602135 = query.getOrDefault("APIVersion")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "APIVersion", valid_602135
  var valid_602136 = query.getOrDefault("Version")
  valid_602136 = validateParameter(valid_602136, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602136 != nil:
    section.add "Version", valid_602136
  var valid_602137 = query.getOrDefault("SignatureVersion")
  valid_602137 = validateParameter(valid_602137, JString, required = true,
                                 default = nil)
  if valid_602137 != nil:
    section.add "SignatureVersion", valid_602137
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602138: Call_GetListJobs_602124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_602138.validator(path, query, header, formData, body)
  let scheme = call_602138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602138.url(scheme.get, call_602138.host, call_602138.base,
                         call_602138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602138, url, valid)

proc call*(call_602139: Call_GetListJobs_602124; Signature: string;
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
  var query_602140 = newJObject()
  add(query_602140, "MaxJobs", newJInt(MaxJobs))
  add(query_602140, "Marker", newJString(Marker))
  add(query_602140, "Signature", newJString(Signature))
  add(query_602140, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602140, "SignatureMethod", newJString(SignatureMethod))
  add(query_602140, "Timestamp", newJString(Timestamp))
  add(query_602140, "Action", newJString(Action))
  add(query_602140, "Operation", newJString(Operation))
  add(query_602140, "APIVersion", newJString(APIVersion))
  add(query_602140, "Version", newJString(Version))
  add(query_602140, "SignatureVersion", newJString(SignatureVersion))
  result = call_602139.call(nil, query_602140, nil, nil, nil)

var getListJobs* = Call_GetListJobs_602124(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_602125,
                                        base: "/", url: url_GetListJobs_602126,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_602178 = ref object of OpenApiRestCall_601373
proc url_PostUpdateJob_602180(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateJob_602179(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602181 = query.getOrDefault("Signature")
  valid_602181 = validateParameter(valid_602181, JString, required = true,
                                 default = nil)
  if valid_602181 != nil:
    section.add "Signature", valid_602181
  var valid_602182 = query.getOrDefault("AWSAccessKeyId")
  valid_602182 = validateParameter(valid_602182, JString, required = true,
                                 default = nil)
  if valid_602182 != nil:
    section.add "AWSAccessKeyId", valid_602182
  var valid_602183 = query.getOrDefault("SignatureMethod")
  valid_602183 = validateParameter(valid_602183, JString, required = true,
                                 default = nil)
  if valid_602183 != nil:
    section.add "SignatureMethod", valid_602183
  var valid_602184 = query.getOrDefault("Timestamp")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "Timestamp", valid_602184
  var valid_602185 = query.getOrDefault("Action")
  valid_602185 = validateParameter(valid_602185, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_602185 != nil:
    section.add "Action", valid_602185
  var valid_602186 = query.getOrDefault("Operation")
  valid_602186 = validateParameter(valid_602186, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_602186 != nil:
    section.add "Operation", valid_602186
  var valid_602187 = query.getOrDefault("Version")
  valid_602187 = validateParameter(valid_602187, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602187 != nil:
    section.add "Version", valid_602187
  var valid_602188 = query.getOrDefault("SignatureVersion")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = nil)
  if valid_602188 != nil:
    section.add "SignatureVersion", valid_602188
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
  var valid_602189 = formData.getOrDefault("ValidateOnly")
  valid_602189 = validateParameter(valid_602189, JBool, required = true, default = nil)
  if valid_602189 != nil:
    section.add "ValidateOnly", valid_602189
  var valid_602190 = formData.getOrDefault("APIVersion")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "APIVersion", valid_602190
  var valid_602191 = formData.getOrDefault("JobId")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = nil)
  if valid_602191 != nil:
    section.add "JobId", valid_602191
  var valid_602192 = formData.getOrDefault("JobType")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = newJString("Import"))
  if valid_602192 != nil:
    section.add "JobType", valid_602192
  var valid_602193 = formData.getOrDefault("Manifest")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = nil)
  if valid_602193 != nil:
    section.add "Manifest", valid_602193
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602194: Call_PostUpdateJob_602178; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_602194.validator(path, query, header, formData, body)
  let scheme = call_602194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602194.url(scheme.get, call_602194.host, call_602194.base,
                         call_602194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602194, url, valid)

proc call*(call_602195: Call_PostUpdateJob_602178; Signature: string;
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
  var query_602196 = newJObject()
  var formData_602197 = newJObject()
  add(query_602196, "Signature", newJString(Signature))
  add(query_602196, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602196, "SignatureMethod", newJString(SignatureMethod))
  add(formData_602197, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_602197, "APIVersion", newJString(APIVersion))
  add(query_602196, "Timestamp", newJString(Timestamp))
  add(query_602196, "Action", newJString(Action))
  add(query_602196, "Operation", newJString(Operation))
  add(formData_602197, "JobId", newJString(JobId))
  add(query_602196, "Version", newJString(Version))
  add(formData_602197, "JobType", newJString(JobType))
  add(query_602196, "SignatureVersion", newJString(SignatureVersion))
  add(formData_602197, "Manifest", newJString(Manifest))
  result = call_602195.call(nil, query_602196, nil, formData_602197, nil)

var postUpdateJob* = Call_PostUpdateJob_602178(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_602179, base: "/", url: url_PostUpdateJob_602180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_602159 = ref object of OpenApiRestCall_601373
proc url_GetUpdateJob_602161(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateJob_602160(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602162 = query.getOrDefault("Signature")
  valid_602162 = validateParameter(valid_602162, JString, required = true,
                                 default = nil)
  if valid_602162 != nil:
    section.add "Signature", valid_602162
  var valid_602163 = query.getOrDefault("JobType")
  valid_602163 = validateParameter(valid_602163, JString, required = true,
                                 default = newJString("Import"))
  if valid_602163 != nil:
    section.add "JobType", valid_602163
  var valid_602164 = query.getOrDefault("AWSAccessKeyId")
  valid_602164 = validateParameter(valid_602164, JString, required = true,
                                 default = nil)
  if valid_602164 != nil:
    section.add "AWSAccessKeyId", valid_602164
  var valid_602165 = query.getOrDefault("SignatureMethod")
  valid_602165 = validateParameter(valid_602165, JString, required = true,
                                 default = nil)
  if valid_602165 != nil:
    section.add "SignatureMethod", valid_602165
  var valid_602166 = query.getOrDefault("Manifest")
  valid_602166 = validateParameter(valid_602166, JString, required = true,
                                 default = nil)
  if valid_602166 != nil:
    section.add "Manifest", valid_602166
  var valid_602167 = query.getOrDefault("ValidateOnly")
  valid_602167 = validateParameter(valid_602167, JBool, required = true, default = nil)
  if valid_602167 != nil:
    section.add "ValidateOnly", valid_602167
  var valid_602168 = query.getOrDefault("Timestamp")
  valid_602168 = validateParameter(valid_602168, JString, required = true,
                                 default = nil)
  if valid_602168 != nil:
    section.add "Timestamp", valid_602168
  var valid_602169 = query.getOrDefault("Action")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_602169 != nil:
    section.add "Action", valid_602169
  var valid_602170 = query.getOrDefault("Operation")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_602170 != nil:
    section.add "Operation", valid_602170
  var valid_602171 = query.getOrDefault("APIVersion")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "APIVersion", valid_602171
  var valid_602172 = query.getOrDefault("Version")
  valid_602172 = validateParameter(valid_602172, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602172 != nil:
    section.add "Version", valid_602172
  var valid_602173 = query.getOrDefault("JobId")
  valid_602173 = validateParameter(valid_602173, JString, required = true,
                                 default = nil)
  if valid_602173 != nil:
    section.add "JobId", valid_602173
  var valid_602174 = query.getOrDefault("SignatureVersion")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = nil)
  if valid_602174 != nil:
    section.add "SignatureVersion", valid_602174
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602175: Call_GetUpdateJob_602159; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_602175.validator(path, query, header, formData, body)
  let scheme = call_602175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602175.url(scheme.get, call_602175.host, call_602175.base,
                         call_602175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602175, url, valid)

proc call*(call_602176: Call_GetUpdateJob_602159; Signature: string;
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
  var query_602177 = newJObject()
  add(query_602177, "Signature", newJString(Signature))
  add(query_602177, "JobType", newJString(JobType))
  add(query_602177, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602177, "SignatureMethod", newJString(SignatureMethod))
  add(query_602177, "Manifest", newJString(Manifest))
  add(query_602177, "ValidateOnly", newJBool(ValidateOnly))
  add(query_602177, "Timestamp", newJString(Timestamp))
  add(query_602177, "Action", newJString(Action))
  add(query_602177, "Operation", newJString(Operation))
  add(query_602177, "APIVersion", newJString(APIVersion))
  add(query_602177, "Version", newJString(Version))
  add(query_602177, "JobId", newJString(JobId))
  add(query_602177, "SignatureVersion", newJString(SignatureVersion))
  result = call_602176.call(nil, query_602177, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_602159(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_602160, base: "/", url: url_GetUpdateJob_602161,
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
