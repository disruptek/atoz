
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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
  Call_PostCancelJob_594029 = ref object of OpenApiRestCall_593421
proc url_PostCancelJob_594031(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCancelJob_594030(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594032 = query.getOrDefault("SignatureMethod")
  valid_594032 = validateParameter(valid_594032, JString, required = true,
                                 default = nil)
  if valid_594032 != nil:
    section.add "SignatureMethod", valid_594032
  var valid_594033 = query.getOrDefault("Signature")
  valid_594033 = validateParameter(valid_594033, JString, required = true,
                                 default = nil)
  if valid_594033 != nil:
    section.add "Signature", valid_594033
  var valid_594034 = query.getOrDefault("Action")
  valid_594034 = validateParameter(valid_594034, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_594034 != nil:
    section.add "Action", valid_594034
  var valid_594035 = query.getOrDefault("Timestamp")
  valid_594035 = validateParameter(valid_594035, JString, required = true,
                                 default = nil)
  if valid_594035 != nil:
    section.add "Timestamp", valid_594035
  var valid_594036 = query.getOrDefault("Operation")
  valid_594036 = validateParameter(valid_594036, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_594036 != nil:
    section.add "Operation", valid_594036
  var valid_594037 = query.getOrDefault("SignatureVersion")
  valid_594037 = validateParameter(valid_594037, JString, required = true,
                                 default = nil)
  if valid_594037 != nil:
    section.add "SignatureVersion", valid_594037
  var valid_594038 = query.getOrDefault("AWSAccessKeyId")
  valid_594038 = validateParameter(valid_594038, JString, required = true,
                                 default = nil)
  if valid_594038 != nil:
    section.add "AWSAccessKeyId", valid_594038
  var valid_594039 = query.getOrDefault("Version")
  valid_594039 = validateParameter(valid_594039, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594039 != nil:
    section.add "Version", valid_594039
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
  var valid_594040 = formData.getOrDefault("JobId")
  valid_594040 = validateParameter(valid_594040, JString, required = true,
                                 default = nil)
  if valid_594040 != nil:
    section.add "JobId", valid_594040
  var valid_594041 = formData.getOrDefault("APIVersion")
  valid_594041 = validateParameter(valid_594041, JString, required = false,
                                 default = nil)
  if valid_594041 != nil:
    section.add "APIVersion", valid_594041
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594042: Call_PostCancelJob_594029; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_594042.validator(path, query, header, formData, body)
  let scheme = call_594042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594042.url(scheme.get, call_594042.host, call_594042.base,
                         call_594042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594042, url, valid)

proc call*(call_594043: Call_PostCancelJob_594029; SignatureMethod: string;
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
  var query_594044 = newJObject()
  var formData_594045 = newJObject()
  add(query_594044, "SignatureMethod", newJString(SignatureMethod))
  add(query_594044, "Signature", newJString(Signature))
  add(query_594044, "Action", newJString(Action))
  add(query_594044, "Timestamp", newJString(Timestamp))
  add(formData_594045, "JobId", newJString(JobId))
  add(query_594044, "Operation", newJString(Operation))
  add(query_594044, "SignatureVersion", newJString(SignatureVersion))
  add(query_594044, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594044, "Version", newJString(Version))
  add(formData_594045, "APIVersion", newJString(APIVersion))
  result = call_594043.call(nil, query_594044, nil, formData_594045, nil)

var postCancelJob* = Call_PostCancelJob_594029(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_594030, base: "/", url: url_PostCancelJob_594031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_593758 = ref object of OpenApiRestCall_593421
proc url_GetCancelJob_593760(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCancelJob_593759(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593872 = query.getOrDefault("SignatureMethod")
  valid_593872 = validateParameter(valid_593872, JString, required = true,
                                 default = nil)
  if valid_593872 != nil:
    section.add "SignatureMethod", valid_593872
  var valid_593873 = query.getOrDefault("JobId")
  valid_593873 = validateParameter(valid_593873, JString, required = true,
                                 default = nil)
  if valid_593873 != nil:
    section.add "JobId", valid_593873
  var valid_593874 = query.getOrDefault("APIVersion")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "APIVersion", valid_593874
  var valid_593875 = query.getOrDefault("Signature")
  valid_593875 = validateParameter(valid_593875, JString, required = true,
                                 default = nil)
  if valid_593875 != nil:
    section.add "Signature", valid_593875
  var valid_593889 = query.getOrDefault("Action")
  valid_593889 = validateParameter(valid_593889, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_593889 != nil:
    section.add "Action", valid_593889
  var valid_593890 = query.getOrDefault("Timestamp")
  valid_593890 = validateParameter(valid_593890, JString, required = true,
                                 default = nil)
  if valid_593890 != nil:
    section.add "Timestamp", valid_593890
  var valid_593891 = query.getOrDefault("Operation")
  valid_593891 = validateParameter(valid_593891, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_593891 != nil:
    section.add "Operation", valid_593891
  var valid_593892 = query.getOrDefault("SignatureVersion")
  valid_593892 = validateParameter(valid_593892, JString, required = true,
                                 default = nil)
  if valid_593892 != nil:
    section.add "SignatureVersion", valid_593892
  var valid_593893 = query.getOrDefault("AWSAccessKeyId")
  valid_593893 = validateParameter(valid_593893, JString, required = true,
                                 default = nil)
  if valid_593893 != nil:
    section.add "AWSAccessKeyId", valid_593893
  var valid_593894 = query.getOrDefault("Version")
  valid_593894 = validateParameter(valid_593894, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_593894 != nil:
    section.add "Version", valid_593894
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593917: Call_GetCancelJob_593758; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_593917.validator(path, query, header, formData, body)
  let scheme = call_593917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593917.url(scheme.get, call_593917.host, call_593917.base,
                         call_593917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593917, url, valid)

proc call*(call_593988: Call_GetCancelJob_593758; SignatureMethod: string;
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
  var query_593989 = newJObject()
  add(query_593989, "SignatureMethod", newJString(SignatureMethod))
  add(query_593989, "JobId", newJString(JobId))
  add(query_593989, "APIVersion", newJString(APIVersion))
  add(query_593989, "Signature", newJString(Signature))
  add(query_593989, "Action", newJString(Action))
  add(query_593989, "Timestamp", newJString(Timestamp))
  add(query_593989, "Operation", newJString(Operation))
  add(query_593989, "SignatureVersion", newJString(SignatureVersion))
  add(query_593989, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_593989, "Version", newJString(Version))
  result = call_593988.call(nil, query_593989, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_593758(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_593759, base: "/", url: url_GetCancelJob_593760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_594065 = ref object of OpenApiRestCall_593421
proc url_PostCreateJob_594067(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateJob_594066(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594068 = query.getOrDefault("SignatureMethod")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = nil)
  if valid_594068 != nil:
    section.add "SignatureMethod", valid_594068
  var valid_594069 = query.getOrDefault("Signature")
  valid_594069 = validateParameter(valid_594069, JString, required = true,
                                 default = nil)
  if valid_594069 != nil:
    section.add "Signature", valid_594069
  var valid_594070 = query.getOrDefault("Action")
  valid_594070 = validateParameter(valid_594070, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_594070 != nil:
    section.add "Action", valid_594070
  var valid_594071 = query.getOrDefault("Timestamp")
  valid_594071 = validateParameter(valid_594071, JString, required = true,
                                 default = nil)
  if valid_594071 != nil:
    section.add "Timestamp", valid_594071
  var valid_594072 = query.getOrDefault("Operation")
  valid_594072 = validateParameter(valid_594072, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_594072 != nil:
    section.add "Operation", valid_594072
  var valid_594073 = query.getOrDefault("SignatureVersion")
  valid_594073 = validateParameter(valid_594073, JString, required = true,
                                 default = nil)
  if valid_594073 != nil:
    section.add "SignatureVersion", valid_594073
  var valid_594074 = query.getOrDefault("AWSAccessKeyId")
  valid_594074 = validateParameter(valid_594074, JString, required = true,
                                 default = nil)
  if valid_594074 != nil:
    section.add "AWSAccessKeyId", valid_594074
  var valid_594075 = query.getOrDefault("Version")
  valid_594075 = validateParameter(valid_594075, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594075 != nil:
    section.add "Version", valid_594075
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
  var valid_594076 = formData.getOrDefault("ManifestAddendum")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "ManifestAddendum", valid_594076
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_594077 = formData.getOrDefault("Manifest")
  valid_594077 = validateParameter(valid_594077, JString, required = true,
                                 default = nil)
  if valid_594077 != nil:
    section.add "Manifest", valid_594077
  var valid_594078 = formData.getOrDefault("JobType")
  valid_594078 = validateParameter(valid_594078, JString, required = true,
                                 default = newJString("Import"))
  if valid_594078 != nil:
    section.add "JobType", valid_594078
  var valid_594079 = formData.getOrDefault("ValidateOnly")
  valid_594079 = validateParameter(valid_594079, JBool, required = true, default = nil)
  if valid_594079 != nil:
    section.add "ValidateOnly", valid_594079
  var valid_594080 = formData.getOrDefault("APIVersion")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "APIVersion", valid_594080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594081: Call_PostCreateJob_594065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_594081.validator(path, query, header, formData, body)
  let scheme = call_594081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594081.url(scheme.get, call_594081.host, call_594081.base,
                         call_594081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594081, url, valid)

proc call*(call_594082: Call_PostCreateJob_594065; SignatureMethod: string;
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
  var query_594083 = newJObject()
  var formData_594084 = newJObject()
  add(query_594083, "SignatureMethod", newJString(SignatureMethod))
  add(formData_594084, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_594083, "Signature", newJString(Signature))
  add(formData_594084, "Manifest", newJString(Manifest))
  add(formData_594084, "JobType", newJString(JobType))
  add(query_594083, "Action", newJString(Action))
  add(query_594083, "Timestamp", newJString(Timestamp))
  add(query_594083, "Operation", newJString(Operation))
  add(query_594083, "SignatureVersion", newJString(SignatureVersion))
  add(query_594083, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594083, "Version", newJString(Version))
  add(formData_594084, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_594084, "APIVersion", newJString(APIVersion))
  result = call_594082.call(nil, query_594083, nil, formData_594084, nil)

var postCreateJob* = Call_PostCreateJob_594065(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_594066, base: "/", url: url_PostCreateJob_594067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_594046 = ref object of OpenApiRestCall_593421
proc url_GetCreateJob_594048(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateJob_594047(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594049 = query.getOrDefault("SignatureMethod")
  valid_594049 = validateParameter(valid_594049, JString, required = true,
                                 default = nil)
  if valid_594049 != nil:
    section.add "SignatureMethod", valid_594049
  var valid_594050 = query.getOrDefault("Manifest")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = nil)
  if valid_594050 != nil:
    section.add "Manifest", valid_594050
  var valid_594051 = query.getOrDefault("APIVersion")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "APIVersion", valid_594051
  var valid_594052 = query.getOrDefault("Signature")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = nil)
  if valid_594052 != nil:
    section.add "Signature", valid_594052
  var valid_594053 = query.getOrDefault("Action")
  valid_594053 = validateParameter(valid_594053, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_594053 != nil:
    section.add "Action", valid_594053
  var valid_594054 = query.getOrDefault("JobType")
  valid_594054 = validateParameter(valid_594054, JString, required = true,
                                 default = newJString("Import"))
  if valid_594054 != nil:
    section.add "JobType", valid_594054
  var valid_594055 = query.getOrDefault("ValidateOnly")
  valid_594055 = validateParameter(valid_594055, JBool, required = true, default = nil)
  if valid_594055 != nil:
    section.add "ValidateOnly", valid_594055
  var valid_594056 = query.getOrDefault("Timestamp")
  valid_594056 = validateParameter(valid_594056, JString, required = true,
                                 default = nil)
  if valid_594056 != nil:
    section.add "Timestamp", valid_594056
  var valid_594057 = query.getOrDefault("ManifestAddendum")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "ManifestAddendum", valid_594057
  var valid_594058 = query.getOrDefault("Operation")
  valid_594058 = validateParameter(valid_594058, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_594058 != nil:
    section.add "Operation", valid_594058
  var valid_594059 = query.getOrDefault("SignatureVersion")
  valid_594059 = validateParameter(valid_594059, JString, required = true,
                                 default = nil)
  if valid_594059 != nil:
    section.add "SignatureVersion", valid_594059
  var valid_594060 = query.getOrDefault("AWSAccessKeyId")
  valid_594060 = validateParameter(valid_594060, JString, required = true,
                                 default = nil)
  if valid_594060 != nil:
    section.add "AWSAccessKeyId", valid_594060
  var valid_594061 = query.getOrDefault("Version")
  valid_594061 = validateParameter(valid_594061, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594061 != nil:
    section.add "Version", valid_594061
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594062: Call_GetCreateJob_594046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_594062.validator(path, query, header, formData, body)
  let scheme = call_594062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594062.url(scheme.get, call_594062.host, call_594062.base,
                         call_594062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594062, url, valid)

proc call*(call_594063: Call_GetCreateJob_594046; SignatureMethod: string;
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
  var query_594064 = newJObject()
  add(query_594064, "SignatureMethod", newJString(SignatureMethod))
  add(query_594064, "Manifest", newJString(Manifest))
  add(query_594064, "APIVersion", newJString(APIVersion))
  add(query_594064, "Signature", newJString(Signature))
  add(query_594064, "Action", newJString(Action))
  add(query_594064, "JobType", newJString(JobType))
  add(query_594064, "ValidateOnly", newJBool(ValidateOnly))
  add(query_594064, "Timestamp", newJString(Timestamp))
  add(query_594064, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_594064, "Operation", newJString(Operation))
  add(query_594064, "SignatureVersion", newJString(SignatureVersion))
  add(query_594064, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594064, "Version", newJString(Version))
  result = call_594063.call(nil, query_594064, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_594046(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_594047, base: "/", url: url_GetCreateJob_594048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_594111 = ref object of OpenApiRestCall_593421
proc url_PostGetShippingLabel_594113(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetShippingLabel_594112(path: JsonNode; query: JsonNode;
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
  var valid_594114 = query.getOrDefault("SignatureMethod")
  valid_594114 = validateParameter(valid_594114, JString, required = true,
                                 default = nil)
  if valid_594114 != nil:
    section.add "SignatureMethod", valid_594114
  var valid_594115 = query.getOrDefault("Signature")
  valid_594115 = validateParameter(valid_594115, JString, required = true,
                                 default = nil)
  if valid_594115 != nil:
    section.add "Signature", valid_594115
  var valid_594116 = query.getOrDefault("Action")
  valid_594116 = validateParameter(valid_594116, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_594116 != nil:
    section.add "Action", valid_594116
  var valid_594117 = query.getOrDefault("Timestamp")
  valid_594117 = validateParameter(valid_594117, JString, required = true,
                                 default = nil)
  if valid_594117 != nil:
    section.add "Timestamp", valid_594117
  var valid_594118 = query.getOrDefault("Operation")
  valid_594118 = validateParameter(valid_594118, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_594118 != nil:
    section.add "Operation", valid_594118
  var valid_594119 = query.getOrDefault("SignatureVersion")
  valid_594119 = validateParameter(valid_594119, JString, required = true,
                                 default = nil)
  if valid_594119 != nil:
    section.add "SignatureVersion", valid_594119
  var valid_594120 = query.getOrDefault("AWSAccessKeyId")
  valid_594120 = validateParameter(valid_594120, JString, required = true,
                                 default = nil)
  if valid_594120 != nil:
    section.add "AWSAccessKeyId", valid_594120
  var valid_594121 = query.getOrDefault("Version")
  valid_594121 = validateParameter(valid_594121, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594121 != nil:
    section.add "Version", valid_594121
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
  var valid_594122 = formData.getOrDefault("company")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "company", valid_594122
  var valid_594123 = formData.getOrDefault("stateOrProvince")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "stateOrProvince", valid_594123
  var valid_594124 = formData.getOrDefault("street1")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "street1", valid_594124
  var valid_594125 = formData.getOrDefault("name")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "name", valid_594125
  var valid_594126 = formData.getOrDefault("street3")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "street3", valid_594126
  var valid_594127 = formData.getOrDefault("city")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "city", valid_594127
  var valid_594128 = formData.getOrDefault("postalCode")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "postalCode", valid_594128
  var valid_594129 = formData.getOrDefault("phoneNumber")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "phoneNumber", valid_594129
  var valid_594130 = formData.getOrDefault("street2")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "street2", valid_594130
  var valid_594131 = formData.getOrDefault("country")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "country", valid_594131
  var valid_594132 = formData.getOrDefault("APIVersion")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "APIVersion", valid_594132
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_594133 = formData.getOrDefault("jobIds")
  valid_594133 = validateParameter(valid_594133, JArray, required = true, default = nil)
  if valid_594133 != nil:
    section.add "jobIds", valid_594133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594134: Call_PostGetShippingLabel_594111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_PostGetShippingLabel_594111; SignatureMethod: string;
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
  var query_594136 = newJObject()
  var formData_594137 = newJObject()
  add(formData_594137, "company", newJString(company))
  add(query_594136, "SignatureMethod", newJString(SignatureMethod))
  add(formData_594137, "stateOrProvince", newJString(stateOrProvince))
  add(query_594136, "Signature", newJString(Signature))
  add(formData_594137, "street1", newJString(street1))
  add(formData_594137, "name", newJString(name))
  add(formData_594137, "street3", newJString(street3))
  add(query_594136, "Action", newJString(Action))
  add(formData_594137, "city", newJString(city))
  add(query_594136, "Timestamp", newJString(Timestamp))
  add(formData_594137, "postalCode", newJString(postalCode))
  add(query_594136, "Operation", newJString(Operation))
  add(query_594136, "SignatureVersion", newJString(SignatureVersion))
  add(formData_594137, "phoneNumber", newJString(phoneNumber))
  add(query_594136, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_594137, "street2", newJString(street2))
  add(query_594136, "Version", newJString(Version))
  add(formData_594137, "country", newJString(country))
  add(formData_594137, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_594137.add "jobIds", jobIds
  result = call_594135.call(nil, query_594136, nil, formData_594137, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_594111(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_594112, base: "/",
    url: url_PostGetShippingLabel_594113, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_594085 = ref object of OpenApiRestCall_593421
proc url_GetGetShippingLabel_594087(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetShippingLabel_594086(path: JsonNode; query: JsonNode;
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
  var valid_594088 = query.getOrDefault("SignatureMethod")
  valid_594088 = validateParameter(valid_594088, JString, required = true,
                                 default = nil)
  if valid_594088 != nil:
    section.add "SignatureMethod", valid_594088
  var valid_594089 = query.getOrDefault("city")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "city", valid_594089
  var valid_594090 = query.getOrDefault("country")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "country", valid_594090
  var valid_594091 = query.getOrDefault("stateOrProvince")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "stateOrProvince", valid_594091
  var valid_594092 = query.getOrDefault("company")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "company", valid_594092
  var valid_594093 = query.getOrDefault("APIVersion")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "APIVersion", valid_594093
  var valid_594094 = query.getOrDefault("phoneNumber")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "phoneNumber", valid_594094
  var valid_594095 = query.getOrDefault("street1")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "street1", valid_594095
  var valid_594096 = query.getOrDefault("Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = nil)
  if valid_594096 != nil:
    section.add "Signature", valid_594096
  var valid_594097 = query.getOrDefault("street3")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "street3", valid_594097
  var valid_594098 = query.getOrDefault("Action")
  valid_594098 = validateParameter(valid_594098, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_594098 != nil:
    section.add "Action", valid_594098
  var valid_594099 = query.getOrDefault("name")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "name", valid_594099
  var valid_594100 = query.getOrDefault("Timestamp")
  valid_594100 = validateParameter(valid_594100, JString, required = true,
                                 default = nil)
  if valid_594100 != nil:
    section.add "Timestamp", valid_594100
  var valid_594101 = query.getOrDefault("Operation")
  valid_594101 = validateParameter(valid_594101, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_594101 != nil:
    section.add "Operation", valid_594101
  var valid_594102 = query.getOrDefault("SignatureVersion")
  valid_594102 = validateParameter(valid_594102, JString, required = true,
                                 default = nil)
  if valid_594102 != nil:
    section.add "SignatureVersion", valid_594102
  var valid_594103 = query.getOrDefault("jobIds")
  valid_594103 = validateParameter(valid_594103, JArray, required = true, default = nil)
  if valid_594103 != nil:
    section.add "jobIds", valid_594103
  var valid_594104 = query.getOrDefault("AWSAccessKeyId")
  valid_594104 = validateParameter(valid_594104, JString, required = true,
                                 default = nil)
  if valid_594104 != nil:
    section.add "AWSAccessKeyId", valid_594104
  var valid_594105 = query.getOrDefault("street2")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "street2", valid_594105
  var valid_594106 = query.getOrDefault("postalCode")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "postalCode", valid_594106
  var valid_594107 = query.getOrDefault("Version")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594107 != nil:
    section.add "Version", valid_594107
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594108: Call_GetGetShippingLabel_594085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_594108.validator(path, query, header, formData, body)
  let scheme = call_594108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594108.url(scheme.get, call_594108.host, call_594108.base,
                         call_594108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594108, url, valid)

proc call*(call_594109: Call_GetGetShippingLabel_594085; SignatureMethod: string;
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
  var query_594110 = newJObject()
  add(query_594110, "SignatureMethod", newJString(SignatureMethod))
  add(query_594110, "city", newJString(city))
  add(query_594110, "country", newJString(country))
  add(query_594110, "stateOrProvince", newJString(stateOrProvince))
  add(query_594110, "company", newJString(company))
  add(query_594110, "APIVersion", newJString(APIVersion))
  add(query_594110, "phoneNumber", newJString(phoneNumber))
  add(query_594110, "street1", newJString(street1))
  add(query_594110, "Signature", newJString(Signature))
  add(query_594110, "street3", newJString(street3))
  add(query_594110, "Action", newJString(Action))
  add(query_594110, "name", newJString(name))
  add(query_594110, "Timestamp", newJString(Timestamp))
  add(query_594110, "Operation", newJString(Operation))
  add(query_594110, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_594110.add "jobIds", jobIds
  add(query_594110, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594110, "street2", newJString(street2))
  add(query_594110, "postalCode", newJString(postalCode))
  add(query_594110, "Version", newJString(Version))
  result = call_594109.call(nil, query_594110, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_594085(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_594086, base: "/",
    url: url_GetGetShippingLabel_594087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_594154 = ref object of OpenApiRestCall_593421
proc url_PostGetStatus_594156(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetStatus_594155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594157 = query.getOrDefault("SignatureMethod")
  valid_594157 = validateParameter(valid_594157, JString, required = true,
                                 default = nil)
  if valid_594157 != nil:
    section.add "SignatureMethod", valid_594157
  var valid_594158 = query.getOrDefault("Signature")
  valid_594158 = validateParameter(valid_594158, JString, required = true,
                                 default = nil)
  if valid_594158 != nil:
    section.add "Signature", valid_594158
  var valid_594159 = query.getOrDefault("Action")
  valid_594159 = validateParameter(valid_594159, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_594159 != nil:
    section.add "Action", valid_594159
  var valid_594160 = query.getOrDefault("Timestamp")
  valid_594160 = validateParameter(valid_594160, JString, required = true,
                                 default = nil)
  if valid_594160 != nil:
    section.add "Timestamp", valid_594160
  var valid_594161 = query.getOrDefault("Operation")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_594161 != nil:
    section.add "Operation", valid_594161
  var valid_594162 = query.getOrDefault("SignatureVersion")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "SignatureVersion", valid_594162
  var valid_594163 = query.getOrDefault("AWSAccessKeyId")
  valid_594163 = validateParameter(valid_594163, JString, required = true,
                                 default = nil)
  if valid_594163 != nil:
    section.add "AWSAccessKeyId", valid_594163
  var valid_594164 = query.getOrDefault("Version")
  valid_594164 = validateParameter(valid_594164, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594164 != nil:
    section.add "Version", valid_594164
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
  var valid_594165 = formData.getOrDefault("JobId")
  valid_594165 = validateParameter(valid_594165, JString, required = true,
                                 default = nil)
  if valid_594165 != nil:
    section.add "JobId", valid_594165
  var valid_594166 = formData.getOrDefault("APIVersion")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "APIVersion", valid_594166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594167: Call_PostGetStatus_594154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_594167.validator(path, query, header, formData, body)
  let scheme = call_594167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594167.url(scheme.get, call_594167.host, call_594167.base,
                         call_594167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594167, url, valid)

proc call*(call_594168: Call_PostGetStatus_594154; SignatureMethod: string;
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
  var query_594169 = newJObject()
  var formData_594170 = newJObject()
  add(query_594169, "SignatureMethod", newJString(SignatureMethod))
  add(query_594169, "Signature", newJString(Signature))
  add(query_594169, "Action", newJString(Action))
  add(query_594169, "Timestamp", newJString(Timestamp))
  add(formData_594170, "JobId", newJString(JobId))
  add(query_594169, "Operation", newJString(Operation))
  add(query_594169, "SignatureVersion", newJString(SignatureVersion))
  add(query_594169, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594169, "Version", newJString(Version))
  add(formData_594170, "APIVersion", newJString(APIVersion))
  result = call_594168.call(nil, query_594169, nil, formData_594170, nil)

var postGetStatus* = Call_PostGetStatus_594154(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_594155, base: "/", url: url_PostGetStatus_594156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_594138 = ref object of OpenApiRestCall_593421
proc url_GetGetStatus_594140(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetStatus_594139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594141 = query.getOrDefault("SignatureMethod")
  valid_594141 = validateParameter(valid_594141, JString, required = true,
                                 default = nil)
  if valid_594141 != nil:
    section.add "SignatureMethod", valid_594141
  var valid_594142 = query.getOrDefault("JobId")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = nil)
  if valid_594142 != nil:
    section.add "JobId", valid_594142
  var valid_594143 = query.getOrDefault("APIVersion")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "APIVersion", valid_594143
  var valid_594144 = query.getOrDefault("Signature")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = nil)
  if valid_594144 != nil:
    section.add "Signature", valid_594144
  var valid_594145 = query.getOrDefault("Action")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_594145 != nil:
    section.add "Action", valid_594145
  var valid_594146 = query.getOrDefault("Timestamp")
  valid_594146 = validateParameter(valid_594146, JString, required = true,
                                 default = nil)
  if valid_594146 != nil:
    section.add "Timestamp", valid_594146
  var valid_594147 = query.getOrDefault("Operation")
  valid_594147 = validateParameter(valid_594147, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_594147 != nil:
    section.add "Operation", valid_594147
  var valid_594148 = query.getOrDefault("SignatureVersion")
  valid_594148 = validateParameter(valid_594148, JString, required = true,
                                 default = nil)
  if valid_594148 != nil:
    section.add "SignatureVersion", valid_594148
  var valid_594149 = query.getOrDefault("AWSAccessKeyId")
  valid_594149 = validateParameter(valid_594149, JString, required = true,
                                 default = nil)
  if valid_594149 != nil:
    section.add "AWSAccessKeyId", valid_594149
  var valid_594150 = query.getOrDefault("Version")
  valid_594150 = validateParameter(valid_594150, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594150 != nil:
    section.add "Version", valid_594150
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594151: Call_GetGetStatus_594138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_594151.validator(path, query, header, formData, body)
  let scheme = call_594151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594151.url(scheme.get, call_594151.host, call_594151.base,
                         call_594151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594151, url, valid)

proc call*(call_594152: Call_GetGetStatus_594138; SignatureMethod: string;
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
  var query_594153 = newJObject()
  add(query_594153, "SignatureMethod", newJString(SignatureMethod))
  add(query_594153, "JobId", newJString(JobId))
  add(query_594153, "APIVersion", newJString(APIVersion))
  add(query_594153, "Signature", newJString(Signature))
  add(query_594153, "Action", newJString(Action))
  add(query_594153, "Timestamp", newJString(Timestamp))
  add(query_594153, "Operation", newJString(Operation))
  add(query_594153, "SignatureVersion", newJString(SignatureVersion))
  add(query_594153, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594153, "Version", newJString(Version))
  result = call_594152.call(nil, query_594153, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_594138(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_594139, base: "/", url: url_GetGetStatus_594140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_594188 = ref object of OpenApiRestCall_593421
proc url_PostListJobs_594190(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListJobs_594189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594191 = query.getOrDefault("SignatureMethod")
  valid_594191 = validateParameter(valid_594191, JString, required = true,
                                 default = nil)
  if valid_594191 != nil:
    section.add "SignatureMethod", valid_594191
  var valid_594192 = query.getOrDefault("Signature")
  valid_594192 = validateParameter(valid_594192, JString, required = true,
                                 default = nil)
  if valid_594192 != nil:
    section.add "Signature", valid_594192
  var valid_594193 = query.getOrDefault("Action")
  valid_594193 = validateParameter(valid_594193, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_594193 != nil:
    section.add "Action", valid_594193
  var valid_594194 = query.getOrDefault("Timestamp")
  valid_594194 = validateParameter(valid_594194, JString, required = true,
                                 default = nil)
  if valid_594194 != nil:
    section.add "Timestamp", valid_594194
  var valid_594195 = query.getOrDefault("Operation")
  valid_594195 = validateParameter(valid_594195, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_594195 != nil:
    section.add "Operation", valid_594195
  var valid_594196 = query.getOrDefault("SignatureVersion")
  valid_594196 = validateParameter(valid_594196, JString, required = true,
                                 default = nil)
  if valid_594196 != nil:
    section.add "SignatureVersion", valid_594196
  var valid_594197 = query.getOrDefault("AWSAccessKeyId")
  valid_594197 = validateParameter(valid_594197, JString, required = true,
                                 default = nil)
  if valid_594197 != nil:
    section.add "AWSAccessKeyId", valid_594197
  var valid_594198 = query.getOrDefault("Version")
  valid_594198 = validateParameter(valid_594198, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594198 != nil:
    section.add "Version", valid_594198
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
  var valid_594199 = formData.getOrDefault("Marker")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "Marker", valid_594199
  var valid_594200 = formData.getOrDefault("MaxJobs")
  valid_594200 = validateParameter(valid_594200, JInt, required = false, default = nil)
  if valid_594200 != nil:
    section.add "MaxJobs", valid_594200
  var valid_594201 = formData.getOrDefault("APIVersion")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "APIVersion", valid_594201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594202: Call_PostListJobs_594188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_594202.validator(path, query, header, formData, body)
  let scheme = call_594202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594202.url(scheme.get, call_594202.host, call_594202.base,
                         call_594202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594202, url, valid)

proc call*(call_594203: Call_PostListJobs_594188; SignatureMethod: string;
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
  var query_594204 = newJObject()
  var formData_594205 = newJObject()
  add(query_594204, "SignatureMethod", newJString(SignatureMethod))
  add(query_594204, "Signature", newJString(Signature))
  add(formData_594205, "Marker", newJString(Marker))
  add(query_594204, "Action", newJString(Action))
  add(formData_594205, "MaxJobs", newJInt(MaxJobs))
  add(query_594204, "Timestamp", newJString(Timestamp))
  add(query_594204, "Operation", newJString(Operation))
  add(query_594204, "SignatureVersion", newJString(SignatureVersion))
  add(query_594204, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594204, "Version", newJString(Version))
  add(formData_594205, "APIVersion", newJString(APIVersion))
  result = call_594203.call(nil, query_594204, nil, formData_594205, nil)

var postListJobs* = Call_PostListJobs_594188(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_594189, base: "/", url: url_PostListJobs_594190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_594171 = ref object of OpenApiRestCall_593421
proc url_GetListJobs_594173(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListJobs_594172(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594174 = query.getOrDefault("SignatureMethod")
  valid_594174 = validateParameter(valid_594174, JString, required = true,
                                 default = nil)
  if valid_594174 != nil:
    section.add "SignatureMethod", valid_594174
  var valid_594175 = query.getOrDefault("APIVersion")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "APIVersion", valid_594175
  var valid_594176 = query.getOrDefault("Signature")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "Signature", valid_594176
  var valid_594177 = query.getOrDefault("MaxJobs")
  valid_594177 = validateParameter(valid_594177, JInt, required = false, default = nil)
  if valid_594177 != nil:
    section.add "MaxJobs", valid_594177
  var valid_594178 = query.getOrDefault("Action")
  valid_594178 = validateParameter(valid_594178, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_594178 != nil:
    section.add "Action", valid_594178
  var valid_594179 = query.getOrDefault("Marker")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "Marker", valid_594179
  var valid_594180 = query.getOrDefault("Timestamp")
  valid_594180 = validateParameter(valid_594180, JString, required = true,
                                 default = nil)
  if valid_594180 != nil:
    section.add "Timestamp", valid_594180
  var valid_594181 = query.getOrDefault("Operation")
  valid_594181 = validateParameter(valid_594181, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_594181 != nil:
    section.add "Operation", valid_594181
  var valid_594182 = query.getOrDefault("SignatureVersion")
  valid_594182 = validateParameter(valid_594182, JString, required = true,
                                 default = nil)
  if valid_594182 != nil:
    section.add "SignatureVersion", valid_594182
  var valid_594183 = query.getOrDefault("AWSAccessKeyId")
  valid_594183 = validateParameter(valid_594183, JString, required = true,
                                 default = nil)
  if valid_594183 != nil:
    section.add "AWSAccessKeyId", valid_594183
  var valid_594184 = query.getOrDefault("Version")
  valid_594184 = validateParameter(valid_594184, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594184 != nil:
    section.add "Version", valid_594184
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594185: Call_GetListJobs_594171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_594185.validator(path, query, header, formData, body)
  let scheme = call_594185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594185.url(scheme.get, call_594185.host, call_594185.base,
                         call_594185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594185, url, valid)

proc call*(call_594186: Call_GetListJobs_594171; SignatureMethod: string;
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
  var query_594187 = newJObject()
  add(query_594187, "SignatureMethod", newJString(SignatureMethod))
  add(query_594187, "APIVersion", newJString(APIVersion))
  add(query_594187, "Signature", newJString(Signature))
  add(query_594187, "MaxJobs", newJInt(MaxJobs))
  add(query_594187, "Action", newJString(Action))
  add(query_594187, "Marker", newJString(Marker))
  add(query_594187, "Timestamp", newJString(Timestamp))
  add(query_594187, "Operation", newJString(Operation))
  add(query_594187, "SignatureVersion", newJString(SignatureVersion))
  add(query_594187, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594187, "Version", newJString(Version))
  result = call_594186.call(nil, query_594187, nil, nil, nil)

var getListJobs* = Call_GetListJobs_594171(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_594172,
                                        base: "/", url: url_GetListJobs_594173,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_594225 = ref object of OpenApiRestCall_593421
proc url_PostUpdateJob_594227(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateJob_594226(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594228 = query.getOrDefault("SignatureMethod")
  valid_594228 = validateParameter(valid_594228, JString, required = true,
                                 default = nil)
  if valid_594228 != nil:
    section.add "SignatureMethod", valid_594228
  var valid_594229 = query.getOrDefault("Signature")
  valid_594229 = validateParameter(valid_594229, JString, required = true,
                                 default = nil)
  if valid_594229 != nil:
    section.add "Signature", valid_594229
  var valid_594230 = query.getOrDefault("Action")
  valid_594230 = validateParameter(valid_594230, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_594230 != nil:
    section.add "Action", valid_594230
  var valid_594231 = query.getOrDefault("Timestamp")
  valid_594231 = validateParameter(valid_594231, JString, required = true,
                                 default = nil)
  if valid_594231 != nil:
    section.add "Timestamp", valid_594231
  var valid_594232 = query.getOrDefault("Operation")
  valid_594232 = validateParameter(valid_594232, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_594232 != nil:
    section.add "Operation", valid_594232
  var valid_594233 = query.getOrDefault("SignatureVersion")
  valid_594233 = validateParameter(valid_594233, JString, required = true,
                                 default = nil)
  if valid_594233 != nil:
    section.add "SignatureVersion", valid_594233
  var valid_594234 = query.getOrDefault("AWSAccessKeyId")
  valid_594234 = validateParameter(valid_594234, JString, required = true,
                                 default = nil)
  if valid_594234 != nil:
    section.add "AWSAccessKeyId", valid_594234
  var valid_594235 = query.getOrDefault("Version")
  valid_594235 = validateParameter(valid_594235, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594235 != nil:
    section.add "Version", valid_594235
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
  var valid_594236 = formData.getOrDefault("Manifest")
  valid_594236 = validateParameter(valid_594236, JString, required = true,
                                 default = nil)
  if valid_594236 != nil:
    section.add "Manifest", valid_594236
  var valid_594237 = formData.getOrDefault("JobType")
  valid_594237 = validateParameter(valid_594237, JString, required = true,
                                 default = newJString("Import"))
  if valid_594237 != nil:
    section.add "JobType", valid_594237
  var valid_594238 = formData.getOrDefault("JobId")
  valid_594238 = validateParameter(valid_594238, JString, required = true,
                                 default = nil)
  if valid_594238 != nil:
    section.add "JobId", valid_594238
  var valid_594239 = formData.getOrDefault("ValidateOnly")
  valid_594239 = validateParameter(valid_594239, JBool, required = true, default = nil)
  if valid_594239 != nil:
    section.add "ValidateOnly", valid_594239
  var valid_594240 = formData.getOrDefault("APIVersion")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "APIVersion", valid_594240
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594241: Call_PostUpdateJob_594225; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_594241.validator(path, query, header, formData, body)
  let scheme = call_594241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594241.url(scheme.get, call_594241.host, call_594241.base,
                         call_594241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594241, url, valid)

proc call*(call_594242: Call_PostUpdateJob_594225; SignatureMethod: string;
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
  var query_594243 = newJObject()
  var formData_594244 = newJObject()
  add(query_594243, "SignatureMethod", newJString(SignatureMethod))
  add(query_594243, "Signature", newJString(Signature))
  add(formData_594244, "Manifest", newJString(Manifest))
  add(formData_594244, "JobType", newJString(JobType))
  add(query_594243, "Action", newJString(Action))
  add(query_594243, "Timestamp", newJString(Timestamp))
  add(formData_594244, "JobId", newJString(JobId))
  add(query_594243, "Operation", newJString(Operation))
  add(query_594243, "SignatureVersion", newJString(SignatureVersion))
  add(query_594243, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594243, "Version", newJString(Version))
  add(formData_594244, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_594244, "APIVersion", newJString(APIVersion))
  result = call_594242.call(nil, query_594243, nil, formData_594244, nil)

var postUpdateJob* = Call_PostUpdateJob_594225(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_594226, base: "/", url: url_PostUpdateJob_594227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_594206 = ref object of OpenApiRestCall_593421
proc url_GetUpdateJob_594208(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateJob_594207(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594209 = query.getOrDefault("SignatureMethod")
  valid_594209 = validateParameter(valid_594209, JString, required = true,
                                 default = nil)
  if valid_594209 != nil:
    section.add "SignatureMethod", valid_594209
  var valid_594210 = query.getOrDefault("Manifest")
  valid_594210 = validateParameter(valid_594210, JString, required = true,
                                 default = nil)
  if valid_594210 != nil:
    section.add "Manifest", valid_594210
  var valid_594211 = query.getOrDefault("JobId")
  valid_594211 = validateParameter(valid_594211, JString, required = true,
                                 default = nil)
  if valid_594211 != nil:
    section.add "JobId", valid_594211
  var valid_594212 = query.getOrDefault("APIVersion")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "APIVersion", valid_594212
  var valid_594213 = query.getOrDefault("Signature")
  valid_594213 = validateParameter(valid_594213, JString, required = true,
                                 default = nil)
  if valid_594213 != nil:
    section.add "Signature", valid_594213
  var valid_594214 = query.getOrDefault("Action")
  valid_594214 = validateParameter(valid_594214, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_594214 != nil:
    section.add "Action", valid_594214
  var valid_594215 = query.getOrDefault("JobType")
  valid_594215 = validateParameter(valid_594215, JString, required = true,
                                 default = newJString("Import"))
  if valid_594215 != nil:
    section.add "JobType", valid_594215
  var valid_594216 = query.getOrDefault("ValidateOnly")
  valid_594216 = validateParameter(valid_594216, JBool, required = true, default = nil)
  if valid_594216 != nil:
    section.add "ValidateOnly", valid_594216
  var valid_594217 = query.getOrDefault("Timestamp")
  valid_594217 = validateParameter(valid_594217, JString, required = true,
                                 default = nil)
  if valid_594217 != nil:
    section.add "Timestamp", valid_594217
  var valid_594218 = query.getOrDefault("Operation")
  valid_594218 = validateParameter(valid_594218, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_594218 != nil:
    section.add "Operation", valid_594218
  var valid_594219 = query.getOrDefault("SignatureVersion")
  valid_594219 = validateParameter(valid_594219, JString, required = true,
                                 default = nil)
  if valid_594219 != nil:
    section.add "SignatureVersion", valid_594219
  var valid_594220 = query.getOrDefault("AWSAccessKeyId")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = nil)
  if valid_594220 != nil:
    section.add "AWSAccessKeyId", valid_594220
  var valid_594221 = query.getOrDefault("Version")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_594221 != nil:
    section.add "Version", valid_594221
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594222: Call_GetUpdateJob_594206; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_594222.validator(path, query, header, formData, body)
  let scheme = call_594222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594222.url(scheme.get, call_594222.host, call_594222.base,
                         call_594222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594222, url, valid)

proc call*(call_594223: Call_GetUpdateJob_594206; SignatureMethod: string;
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
  var query_594224 = newJObject()
  add(query_594224, "SignatureMethod", newJString(SignatureMethod))
  add(query_594224, "Manifest", newJString(Manifest))
  add(query_594224, "JobId", newJString(JobId))
  add(query_594224, "APIVersion", newJString(APIVersion))
  add(query_594224, "Signature", newJString(Signature))
  add(query_594224, "Action", newJString(Action))
  add(query_594224, "JobType", newJString(JobType))
  add(query_594224, "ValidateOnly", newJBool(ValidateOnly))
  add(query_594224, "Timestamp", newJString(Timestamp))
  add(query_594224, "Operation", newJString(Operation))
  add(query_594224, "SignatureVersion", newJString(SignatureVersion))
  add(query_594224, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_594224, "Version", newJString(Version))
  result = call_594223.call(nil, query_594224, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_594206(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_594207, base: "/", url: url_GetUpdateJob_594208,
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
