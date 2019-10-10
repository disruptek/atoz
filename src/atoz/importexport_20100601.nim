
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

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
  Call_PostCancelJob_603058 = ref object of OpenApiRestCall_602450
proc url_PostCancelJob_603060(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCancelJob_603059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603061 = query.getOrDefault("SignatureMethod")
  valid_603061 = validateParameter(valid_603061, JString, required = true,
                                 default = nil)
  if valid_603061 != nil:
    section.add "SignatureMethod", valid_603061
  var valid_603062 = query.getOrDefault("Signature")
  valid_603062 = validateParameter(valid_603062, JString, required = true,
                                 default = nil)
  if valid_603062 != nil:
    section.add "Signature", valid_603062
  var valid_603063 = query.getOrDefault("Action")
  valid_603063 = validateParameter(valid_603063, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_603063 != nil:
    section.add "Action", valid_603063
  var valid_603064 = query.getOrDefault("Timestamp")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = nil)
  if valid_603064 != nil:
    section.add "Timestamp", valid_603064
  var valid_603065 = query.getOrDefault("Operation")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_603065 != nil:
    section.add "Operation", valid_603065
  var valid_603066 = query.getOrDefault("SignatureVersion")
  valid_603066 = validateParameter(valid_603066, JString, required = true,
                                 default = nil)
  if valid_603066 != nil:
    section.add "SignatureVersion", valid_603066
  var valid_603067 = query.getOrDefault("AWSAccessKeyId")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = nil)
  if valid_603067 != nil:
    section.add "AWSAccessKeyId", valid_603067
  var valid_603068 = query.getOrDefault("Version")
  valid_603068 = validateParameter(valid_603068, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603068 != nil:
    section.add "Version", valid_603068
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
  var valid_603069 = formData.getOrDefault("JobId")
  valid_603069 = validateParameter(valid_603069, JString, required = true,
                                 default = nil)
  if valid_603069 != nil:
    section.add "JobId", valid_603069
  var valid_603070 = formData.getOrDefault("APIVersion")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "APIVersion", valid_603070
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603071: Call_PostCancelJob_603058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_603071.validator(path, query, header, formData, body)
  let scheme = call_603071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603071.url(scheme.get, call_603071.host, call_603071.base,
                         call_603071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603071, url, valid)

proc call*(call_603072: Call_PostCancelJob_603058; SignatureMethod: string;
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
  var query_603073 = newJObject()
  var formData_603074 = newJObject()
  add(query_603073, "SignatureMethod", newJString(SignatureMethod))
  add(query_603073, "Signature", newJString(Signature))
  add(query_603073, "Action", newJString(Action))
  add(query_603073, "Timestamp", newJString(Timestamp))
  add(formData_603074, "JobId", newJString(JobId))
  add(query_603073, "Operation", newJString(Operation))
  add(query_603073, "SignatureVersion", newJString(SignatureVersion))
  add(query_603073, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603073, "Version", newJString(Version))
  add(formData_603074, "APIVersion", newJString(APIVersion))
  result = call_603072.call(nil, query_603073, nil, formData_603074, nil)

var postCancelJob* = Call_PostCancelJob_603058(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_603059, base: "/", url: url_PostCancelJob_603060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_602787 = ref object of OpenApiRestCall_602450
proc url_GetCancelJob_602789(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCancelJob_602788(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602901 = query.getOrDefault("SignatureMethod")
  valid_602901 = validateParameter(valid_602901, JString, required = true,
                                 default = nil)
  if valid_602901 != nil:
    section.add "SignatureMethod", valid_602901
  var valid_602902 = query.getOrDefault("JobId")
  valid_602902 = validateParameter(valid_602902, JString, required = true,
                                 default = nil)
  if valid_602902 != nil:
    section.add "JobId", valid_602902
  var valid_602903 = query.getOrDefault("APIVersion")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "APIVersion", valid_602903
  var valid_602904 = query.getOrDefault("Signature")
  valid_602904 = validateParameter(valid_602904, JString, required = true,
                                 default = nil)
  if valid_602904 != nil:
    section.add "Signature", valid_602904
  var valid_602918 = query.getOrDefault("Action")
  valid_602918 = validateParameter(valid_602918, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_602918 != nil:
    section.add "Action", valid_602918
  var valid_602919 = query.getOrDefault("Timestamp")
  valid_602919 = validateParameter(valid_602919, JString, required = true,
                                 default = nil)
  if valid_602919 != nil:
    section.add "Timestamp", valid_602919
  var valid_602920 = query.getOrDefault("Operation")
  valid_602920 = validateParameter(valid_602920, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_602920 != nil:
    section.add "Operation", valid_602920
  var valid_602921 = query.getOrDefault("SignatureVersion")
  valid_602921 = validateParameter(valid_602921, JString, required = true,
                                 default = nil)
  if valid_602921 != nil:
    section.add "SignatureVersion", valid_602921
  var valid_602922 = query.getOrDefault("AWSAccessKeyId")
  valid_602922 = validateParameter(valid_602922, JString, required = true,
                                 default = nil)
  if valid_602922 != nil:
    section.add "AWSAccessKeyId", valid_602922
  var valid_602923 = query.getOrDefault("Version")
  valid_602923 = validateParameter(valid_602923, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602923 != nil:
    section.add "Version", valid_602923
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602946: Call_GetCancelJob_602787; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_602946.validator(path, query, header, formData, body)
  let scheme = call_602946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602946.url(scheme.get, call_602946.host, call_602946.base,
                         call_602946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602946, url, valid)

proc call*(call_603017: Call_GetCancelJob_602787; SignatureMethod: string;
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
  var query_603018 = newJObject()
  add(query_603018, "SignatureMethod", newJString(SignatureMethod))
  add(query_603018, "JobId", newJString(JobId))
  add(query_603018, "APIVersion", newJString(APIVersion))
  add(query_603018, "Signature", newJString(Signature))
  add(query_603018, "Action", newJString(Action))
  add(query_603018, "Timestamp", newJString(Timestamp))
  add(query_603018, "Operation", newJString(Operation))
  add(query_603018, "SignatureVersion", newJString(SignatureVersion))
  add(query_603018, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603018, "Version", newJString(Version))
  result = call_603017.call(nil, query_603018, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_602787(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_602788, base: "/", url: url_GetCancelJob_602789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_603094 = ref object of OpenApiRestCall_602450
proc url_PostCreateJob_603096(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateJob_603095(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603097 = query.getOrDefault("SignatureMethod")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = nil)
  if valid_603097 != nil:
    section.add "SignatureMethod", valid_603097
  var valid_603098 = query.getOrDefault("Signature")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = nil)
  if valid_603098 != nil:
    section.add "Signature", valid_603098
  var valid_603099 = query.getOrDefault("Action")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603099 != nil:
    section.add "Action", valid_603099
  var valid_603100 = query.getOrDefault("Timestamp")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = nil)
  if valid_603100 != nil:
    section.add "Timestamp", valid_603100
  var valid_603101 = query.getOrDefault("Operation")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603101 != nil:
    section.add "Operation", valid_603101
  var valid_603102 = query.getOrDefault("SignatureVersion")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = nil)
  if valid_603102 != nil:
    section.add "SignatureVersion", valid_603102
  var valid_603103 = query.getOrDefault("AWSAccessKeyId")
  valid_603103 = validateParameter(valid_603103, JString, required = true,
                                 default = nil)
  if valid_603103 != nil:
    section.add "AWSAccessKeyId", valid_603103
  var valid_603104 = query.getOrDefault("Version")
  valid_603104 = validateParameter(valid_603104, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603104 != nil:
    section.add "Version", valid_603104
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
  var valid_603105 = formData.getOrDefault("ManifestAddendum")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "ManifestAddendum", valid_603105
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_603106 = formData.getOrDefault("Manifest")
  valid_603106 = validateParameter(valid_603106, JString, required = true,
                                 default = nil)
  if valid_603106 != nil:
    section.add "Manifest", valid_603106
  var valid_603107 = formData.getOrDefault("JobType")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = newJString("Import"))
  if valid_603107 != nil:
    section.add "JobType", valid_603107
  var valid_603108 = formData.getOrDefault("ValidateOnly")
  valid_603108 = validateParameter(valid_603108, JBool, required = true, default = nil)
  if valid_603108 != nil:
    section.add "ValidateOnly", valid_603108
  var valid_603109 = formData.getOrDefault("APIVersion")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "APIVersion", valid_603109
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603110: Call_PostCreateJob_603094; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_603110.validator(path, query, header, formData, body)
  let scheme = call_603110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603110.url(scheme.get, call_603110.host, call_603110.base,
                         call_603110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603110, url, valid)

proc call*(call_603111: Call_PostCreateJob_603094; SignatureMethod: string;
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
  var query_603112 = newJObject()
  var formData_603113 = newJObject()
  add(query_603112, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603113, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_603112, "Signature", newJString(Signature))
  add(formData_603113, "Manifest", newJString(Manifest))
  add(formData_603113, "JobType", newJString(JobType))
  add(query_603112, "Action", newJString(Action))
  add(query_603112, "Timestamp", newJString(Timestamp))
  add(query_603112, "Operation", newJString(Operation))
  add(query_603112, "SignatureVersion", newJString(SignatureVersion))
  add(query_603112, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603112, "Version", newJString(Version))
  add(formData_603113, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_603113, "APIVersion", newJString(APIVersion))
  result = call_603111.call(nil, query_603112, nil, formData_603113, nil)

var postCreateJob* = Call_PostCreateJob_603094(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_603095, base: "/", url: url_PostCreateJob_603096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_603075 = ref object of OpenApiRestCall_602450
proc url_GetCreateJob_603077(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateJob_603076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603078 = query.getOrDefault("SignatureMethod")
  valid_603078 = validateParameter(valid_603078, JString, required = true,
                                 default = nil)
  if valid_603078 != nil:
    section.add "SignatureMethod", valid_603078
  var valid_603079 = query.getOrDefault("Manifest")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = nil)
  if valid_603079 != nil:
    section.add "Manifest", valid_603079
  var valid_603080 = query.getOrDefault("APIVersion")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "APIVersion", valid_603080
  var valid_603081 = query.getOrDefault("Signature")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = nil)
  if valid_603081 != nil:
    section.add "Signature", valid_603081
  var valid_603082 = query.getOrDefault("Action")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603082 != nil:
    section.add "Action", valid_603082
  var valid_603083 = query.getOrDefault("JobType")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = newJString("Import"))
  if valid_603083 != nil:
    section.add "JobType", valid_603083
  var valid_603084 = query.getOrDefault("ValidateOnly")
  valid_603084 = validateParameter(valid_603084, JBool, required = true, default = nil)
  if valid_603084 != nil:
    section.add "ValidateOnly", valid_603084
  var valid_603085 = query.getOrDefault("Timestamp")
  valid_603085 = validateParameter(valid_603085, JString, required = true,
                                 default = nil)
  if valid_603085 != nil:
    section.add "Timestamp", valid_603085
  var valid_603086 = query.getOrDefault("ManifestAddendum")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "ManifestAddendum", valid_603086
  var valid_603087 = query.getOrDefault("Operation")
  valid_603087 = validateParameter(valid_603087, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603087 != nil:
    section.add "Operation", valid_603087
  var valid_603088 = query.getOrDefault("SignatureVersion")
  valid_603088 = validateParameter(valid_603088, JString, required = true,
                                 default = nil)
  if valid_603088 != nil:
    section.add "SignatureVersion", valid_603088
  var valid_603089 = query.getOrDefault("AWSAccessKeyId")
  valid_603089 = validateParameter(valid_603089, JString, required = true,
                                 default = nil)
  if valid_603089 != nil:
    section.add "AWSAccessKeyId", valid_603089
  var valid_603090 = query.getOrDefault("Version")
  valid_603090 = validateParameter(valid_603090, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603090 != nil:
    section.add "Version", valid_603090
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603091: Call_GetCreateJob_603075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_603091.validator(path, query, header, formData, body)
  let scheme = call_603091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603091.url(scheme.get, call_603091.host, call_603091.base,
                         call_603091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603091, url, valid)

proc call*(call_603092: Call_GetCreateJob_603075; SignatureMethod: string;
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
  var query_603093 = newJObject()
  add(query_603093, "SignatureMethod", newJString(SignatureMethod))
  add(query_603093, "Manifest", newJString(Manifest))
  add(query_603093, "APIVersion", newJString(APIVersion))
  add(query_603093, "Signature", newJString(Signature))
  add(query_603093, "Action", newJString(Action))
  add(query_603093, "JobType", newJString(JobType))
  add(query_603093, "ValidateOnly", newJBool(ValidateOnly))
  add(query_603093, "Timestamp", newJString(Timestamp))
  add(query_603093, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_603093, "Operation", newJString(Operation))
  add(query_603093, "SignatureVersion", newJString(SignatureVersion))
  add(query_603093, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603093, "Version", newJString(Version))
  result = call_603092.call(nil, query_603093, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_603075(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_603076, base: "/", url: url_GetCreateJob_603077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_603140 = ref object of OpenApiRestCall_602450
proc url_PostGetShippingLabel_603142(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetShippingLabel_603141(path: JsonNode; query: JsonNode;
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
  var valid_603143 = query.getOrDefault("SignatureMethod")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = nil)
  if valid_603143 != nil:
    section.add "SignatureMethod", valid_603143
  var valid_603144 = query.getOrDefault("Signature")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "Signature", valid_603144
  var valid_603145 = query.getOrDefault("Action")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603145 != nil:
    section.add "Action", valid_603145
  var valid_603146 = query.getOrDefault("Timestamp")
  valid_603146 = validateParameter(valid_603146, JString, required = true,
                                 default = nil)
  if valid_603146 != nil:
    section.add "Timestamp", valid_603146
  var valid_603147 = query.getOrDefault("Operation")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603147 != nil:
    section.add "Operation", valid_603147
  var valid_603148 = query.getOrDefault("SignatureVersion")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = nil)
  if valid_603148 != nil:
    section.add "SignatureVersion", valid_603148
  var valid_603149 = query.getOrDefault("AWSAccessKeyId")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = nil)
  if valid_603149 != nil:
    section.add "AWSAccessKeyId", valid_603149
  var valid_603150 = query.getOrDefault("Version")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603150 != nil:
    section.add "Version", valid_603150
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
  var valid_603151 = formData.getOrDefault("company")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "company", valid_603151
  var valid_603152 = formData.getOrDefault("stateOrProvince")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "stateOrProvince", valid_603152
  var valid_603153 = formData.getOrDefault("street1")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "street1", valid_603153
  var valid_603154 = formData.getOrDefault("name")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "name", valid_603154
  var valid_603155 = formData.getOrDefault("street3")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "street3", valid_603155
  var valid_603156 = formData.getOrDefault("city")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "city", valid_603156
  var valid_603157 = formData.getOrDefault("postalCode")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "postalCode", valid_603157
  var valid_603158 = formData.getOrDefault("phoneNumber")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "phoneNumber", valid_603158
  var valid_603159 = formData.getOrDefault("street2")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "street2", valid_603159
  var valid_603160 = formData.getOrDefault("country")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "country", valid_603160
  var valid_603161 = formData.getOrDefault("APIVersion")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "APIVersion", valid_603161
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_603162 = formData.getOrDefault("jobIds")
  valid_603162 = validateParameter(valid_603162, JArray, required = true, default = nil)
  if valid_603162 != nil:
    section.add "jobIds", valid_603162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_PostGetShippingLabel_603140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603163, url, valid)

proc call*(call_603164: Call_PostGetShippingLabel_603140; SignatureMethod: string;
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
  var query_603165 = newJObject()
  var formData_603166 = newJObject()
  add(formData_603166, "company", newJString(company))
  add(query_603165, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603166, "stateOrProvince", newJString(stateOrProvince))
  add(query_603165, "Signature", newJString(Signature))
  add(formData_603166, "street1", newJString(street1))
  add(formData_603166, "name", newJString(name))
  add(formData_603166, "street3", newJString(street3))
  add(query_603165, "Action", newJString(Action))
  add(formData_603166, "city", newJString(city))
  add(query_603165, "Timestamp", newJString(Timestamp))
  add(formData_603166, "postalCode", newJString(postalCode))
  add(query_603165, "Operation", newJString(Operation))
  add(query_603165, "SignatureVersion", newJString(SignatureVersion))
  add(formData_603166, "phoneNumber", newJString(phoneNumber))
  add(query_603165, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_603166, "street2", newJString(street2))
  add(query_603165, "Version", newJString(Version))
  add(formData_603166, "country", newJString(country))
  add(formData_603166, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_603166.add "jobIds", jobIds
  result = call_603164.call(nil, query_603165, nil, formData_603166, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_603140(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_603141, base: "/",
    url: url_PostGetShippingLabel_603142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_603114 = ref object of OpenApiRestCall_602450
proc url_GetGetShippingLabel_603116(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetShippingLabel_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = query.getOrDefault("SignatureMethod")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = nil)
  if valid_603117 != nil:
    section.add "SignatureMethod", valid_603117
  var valid_603118 = query.getOrDefault("city")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "city", valid_603118
  var valid_603119 = query.getOrDefault("country")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "country", valid_603119
  var valid_603120 = query.getOrDefault("stateOrProvince")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "stateOrProvince", valid_603120
  var valid_603121 = query.getOrDefault("company")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "company", valid_603121
  var valid_603122 = query.getOrDefault("APIVersion")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "APIVersion", valid_603122
  var valid_603123 = query.getOrDefault("phoneNumber")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "phoneNumber", valid_603123
  var valid_603124 = query.getOrDefault("street1")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "street1", valid_603124
  var valid_603125 = query.getOrDefault("Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "Signature", valid_603125
  var valid_603126 = query.getOrDefault("street3")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "street3", valid_603126
  var valid_603127 = query.getOrDefault("Action")
  valid_603127 = validateParameter(valid_603127, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603127 != nil:
    section.add "Action", valid_603127
  var valid_603128 = query.getOrDefault("name")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "name", valid_603128
  var valid_603129 = query.getOrDefault("Timestamp")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = nil)
  if valid_603129 != nil:
    section.add "Timestamp", valid_603129
  var valid_603130 = query.getOrDefault("Operation")
  valid_603130 = validateParameter(valid_603130, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603130 != nil:
    section.add "Operation", valid_603130
  var valid_603131 = query.getOrDefault("SignatureVersion")
  valid_603131 = validateParameter(valid_603131, JString, required = true,
                                 default = nil)
  if valid_603131 != nil:
    section.add "SignatureVersion", valid_603131
  var valid_603132 = query.getOrDefault("jobIds")
  valid_603132 = validateParameter(valid_603132, JArray, required = true, default = nil)
  if valid_603132 != nil:
    section.add "jobIds", valid_603132
  var valid_603133 = query.getOrDefault("AWSAccessKeyId")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = nil)
  if valid_603133 != nil:
    section.add "AWSAccessKeyId", valid_603133
  var valid_603134 = query.getOrDefault("street2")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "street2", valid_603134
  var valid_603135 = query.getOrDefault("postalCode")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "postalCode", valid_603135
  var valid_603136 = query.getOrDefault("Version")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603136 != nil:
    section.add "Version", valid_603136
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603137: Call_GetGetShippingLabel_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_603137.validator(path, query, header, formData, body)
  let scheme = call_603137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603137.url(scheme.get, call_603137.host, call_603137.base,
                         call_603137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603137, url, valid)

proc call*(call_603138: Call_GetGetShippingLabel_603114; SignatureMethod: string;
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
  var query_603139 = newJObject()
  add(query_603139, "SignatureMethod", newJString(SignatureMethod))
  add(query_603139, "city", newJString(city))
  add(query_603139, "country", newJString(country))
  add(query_603139, "stateOrProvince", newJString(stateOrProvince))
  add(query_603139, "company", newJString(company))
  add(query_603139, "APIVersion", newJString(APIVersion))
  add(query_603139, "phoneNumber", newJString(phoneNumber))
  add(query_603139, "street1", newJString(street1))
  add(query_603139, "Signature", newJString(Signature))
  add(query_603139, "street3", newJString(street3))
  add(query_603139, "Action", newJString(Action))
  add(query_603139, "name", newJString(name))
  add(query_603139, "Timestamp", newJString(Timestamp))
  add(query_603139, "Operation", newJString(Operation))
  add(query_603139, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_603139.add "jobIds", jobIds
  add(query_603139, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603139, "street2", newJString(street2))
  add(query_603139, "postalCode", newJString(postalCode))
  add(query_603139, "Version", newJString(Version))
  result = call_603138.call(nil, query_603139, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_603114(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_603115, base: "/",
    url: url_GetGetShippingLabel_603116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_603183 = ref object of OpenApiRestCall_602450
proc url_PostGetStatus_603185(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostGetStatus_603184(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603186 = query.getOrDefault("SignatureMethod")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = nil)
  if valid_603186 != nil:
    section.add "SignatureMethod", valid_603186
  var valid_603187 = query.getOrDefault("Signature")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = nil)
  if valid_603187 != nil:
    section.add "Signature", valid_603187
  var valid_603188 = query.getOrDefault("Action")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603188 != nil:
    section.add "Action", valid_603188
  var valid_603189 = query.getOrDefault("Timestamp")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = nil)
  if valid_603189 != nil:
    section.add "Timestamp", valid_603189
  var valid_603190 = query.getOrDefault("Operation")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603190 != nil:
    section.add "Operation", valid_603190
  var valid_603191 = query.getOrDefault("SignatureVersion")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = nil)
  if valid_603191 != nil:
    section.add "SignatureVersion", valid_603191
  var valid_603192 = query.getOrDefault("AWSAccessKeyId")
  valid_603192 = validateParameter(valid_603192, JString, required = true,
                                 default = nil)
  if valid_603192 != nil:
    section.add "AWSAccessKeyId", valid_603192
  var valid_603193 = query.getOrDefault("Version")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603193 != nil:
    section.add "Version", valid_603193
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
  var valid_603194 = formData.getOrDefault("JobId")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = nil)
  if valid_603194 != nil:
    section.add "JobId", valid_603194
  var valid_603195 = formData.getOrDefault("APIVersion")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "APIVersion", valid_603195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603196: Call_PostGetStatus_603183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_603196.validator(path, query, header, formData, body)
  let scheme = call_603196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603196.url(scheme.get, call_603196.host, call_603196.base,
                         call_603196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603196, url, valid)

proc call*(call_603197: Call_PostGetStatus_603183; SignatureMethod: string;
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
  var query_603198 = newJObject()
  var formData_603199 = newJObject()
  add(query_603198, "SignatureMethod", newJString(SignatureMethod))
  add(query_603198, "Signature", newJString(Signature))
  add(query_603198, "Action", newJString(Action))
  add(query_603198, "Timestamp", newJString(Timestamp))
  add(formData_603199, "JobId", newJString(JobId))
  add(query_603198, "Operation", newJString(Operation))
  add(query_603198, "SignatureVersion", newJString(SignatureVersion))
  add(query_603198, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603198, "Version", newJString(Version))
  add(formData_603199, "APIVersion", newJString(APIVersion))
  result = call_603197.call(nil, query_603198, nil, formData_603199, nil)

var postGetStatus* = Call_PostGetStatus_603183(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_603184, base: "/", url: url_PostGetStatus_603185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_603167 = ref object of OpenApiRestCall_602450
proc url_GetGetStatus_603169(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGetStatus_603168(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603170 = query.getOrDefault("SignatureMethod")
  valid_603170 = validateParameter(valid_603170, JString, required = true,
                                 default = nil)
  if valid_603170 != nil:
    section.add "SignatureMethod", valid_603170
  var valid_603171 = query.getOrDefault("JobId")
  valid_603171 = validateParameter(valid_603171, JString, required = true,
                                 default = nil)
  if valid_603171 != nil:
    section.add "JobId", valid_603171
  var valid_603172 = query.getOrDefault("APIVersion")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "APIVersion", valid_603172
  var valid_603173 = query.getOrDefault("Signature")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = nil)
  if valid_603173 != nil:
    section.add "Signature", valid_603173
  var valid_603174 = query.getOrDefault("Action")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603174 != nil:
    section.add "Action", valid_603174
  var valid_603175 = query.getOrDefault("Timestamp")
  valid_603175 = validateParameter(valid_603175, JString, required = true,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Timestamp", valid_603175
  var valid_603176 = query.getOrDefault("Operation")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603176 != nil:
    section.add "Operation", valid_603176
  var valid_603177 = query.getOrDefault("SignatureVersion")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = nil)
  if valid_603177 != nil:
    section.add "SignatureVersion", valid_603177
  var valid_603178 = query.getOrDefault("AWSAccessKeyId")
  valid_603178 = validateParameter(valid_603178, JString, required = true,
                                 default = nil)
  if valid_603178 != nil:
    section.add "AWSAccessKeyId", valid_603178
  var valid_603179 = query.getOrDefault("Version")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603179 != nil:
    section.add "Version", valid_603179
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603180: Call_GetGetStatus_603167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_603180.validator(path, query, header, formData, body)
  let scheme = call_603180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603180.url(scheme.get, call_603180.host, call_603180.base,
                         call_603180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603180, url, valid)

proc call*(call_603181: Call_GetGetStatus_603167; SignatureMethod: string;
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
  var query_603182 = newJObject()
  add(query_603182, "SignatureMethod", newJString(SignatureMethod))
  add(query_603182, "JobId", newJString(JobId))
  add(query_603182, "APIVersion", newJString(APIVersion))
  add(query_603182, "Signature", newJString(Signature))
  add(query_603182, "Action", newJString(Action))
  add(query_603182, "Timestamp", newJString(Timestamp))
  add(query_603182, "Operation", newJString(Operation))
  add(query_603182, "SignatureVersion", newJString(SignatureVersion))
  add(query_603182, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603182, "Version", newJString(Version))
  result = call_603181.call(nil, query_603182, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_603167(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_603168, base: "/", url: url_GetGetStatus_603169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_603217 = ref object of OpenApiRestCall_602450
proc url_PostListJobs_603219(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListJobs_603218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603220 = query.getOrDefault("SignatureMethod")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = nil)
  if valid_603220 != nil:
    section.add "SignatureMethod", valid_603220
  var valid_603221 = query.getOrDefault("Signature")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "Signature", valid_603221
  var valid_603222 = query.getOrDefault("Action")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603222 != nil:
    section.add "Action", valid_603222
  var valid_603223 = query.getOrDefault("Timestamp")
  valid_603223 = validateParameter(valid_603223, JString, required = true,
                                 default = nil)
  if valid_603223 != nil:
    section.add "Timestamp", valid_603223
  var valid_603224 = query.getOrDefault("Operation")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603224 != nil:
    section.add "Operation", valid_603224
  var valid_603225 = query.getOrDefault("SignatureVersion")
  valid_603225 = validateParameter(valid_603225, JString, required = true,
                                 default = nil)
  if valid_603225 != nil:
    section.add "SignatureVersion", valid_603225
  var valid_603226 = query.getOrDefault("AWSAccessKeyId")
  valid_603226 = validateParameter(valid_603226, JString, required = true,
                                 default = nil)
  if valid_603226 != nil:
    section.add "AWSAccessKeyId", valid_603226
  var valid_603227 = query.getOrDefault("Version")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603227 != nil:
    section.add "Version", valid_603227
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
  var valid_603228 = formData.getOrDefault("Marker")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "Marker", valid_603228
  var valid_603229 = formData.getOrDefault("MaxJobs")
  valid_603229 = validateParameter(valid_603229, JInt, required = false, default = nil)
  if valid_603229 != nil:
    section.add "MaxJobs", valid_603229
  var valid_603230 = formData.getOrDefault("APIVersion")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "APIVersion", valid_603230
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_PostListJobs_603217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_PostListJobs_603217; SignatureMethod: string;
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
  var query_603233 = newJObject()
  var formData_603234 = newJObject()
  add(query_603233, "SignatureMethod", newJString(SignatureMethod))
  add(query_603233, "Signature", newJString(Signature))
  add(formData_603234, "Marker", newJString(Marker))
  add(query_603233, "Action", newJString(Action))
  add(formData_603234, "MaxJobs", newJInt(MaxJobs))
  add(query_603233, "Timestamp", newJString(Timestamp))
  add(query_603233, "Operation", newJString(Operation))
  add(query_603233, "SignatureVersion", newJString(SignatureVersion))
  add(query_603233, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603233, "Version", newJString(Version))
  add(formData_603234, "APIVersion", newJString(APIVersion))
  result = call_603232.call(nil, query_603233, nil, formData_603234, nil)

var postListJobs* = Call_PostListJobs_603217(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_603218, base: "/", url: url_PostListJobs_603219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_603200 = ref object of OpenApiRestCall_602450
proc url_GetListJobs_603202(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListJobs_603201(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603203 = query.getOrDefault("SignatureMethod")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = nil)
  if valid_603203 != nil:
    section.add "SignatureMethod", valid_603203
  var valid_603204 = query.getOrDefault("APIVersion")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "APIVersion", valid_603204
  var valid_603205 = query.getOrDefault("Signature")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "Signature", valid_603205
  var valid_603206 = query.getOrDefault("MaxJobs")
  valid_603206 = validateParameter(valid_603206, JInt, required = false, default = nil)
  if valid_603206 != nil:
    section.add "MaxJobs", valid_603206
  var valid_603207 = query.getOrDefault("Action")
  valid_603207 = validateParameter(valid_603207, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603207 != nil:
    section.add "Action", valid_603207
  var valid_603208 = query.getOrDefault("Marker")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "Marker", valid_603208
  var valid_603209 = query.getOrDefault("Timestamp")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = nil)
  if valid_603209 != nil:
    section.add "Timestamp", valid_603209
  var valid_603210 = query.getOrDefault("Operation")
  valid_603210 = validateParameter(valid_603210, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603210 != nil:
    section.add "Operation", valid_603210
  var valid_603211 = query.getOrDefault("SignatureVersion")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = nil)
  if valid_603211 != nil:
    section.add "SignatureVersion", valid_603211
  var valid_603212 = query.getOrDefault("AWSAccessKeyId")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = nil)
  if valid_603212 != nil:
    section.add "AWSAccessKeyId", valid_603212
  var valid_603213 = query.getOrDefault("Version")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603213 != nil:
    section.add "Version", valid_603213
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603214: Call_GetListJobs_603200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_603214.validator(path, query, header, formData, body)
  let scheme = call_603214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603214.url(scheme.get, call_603214.host, call_603214.base,
                         call_603214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603214, url, valid)

proc call*(call_603215: Call_GetListJobs_603200; SignatureMethod: string;
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
  var query_603216 = newJObject()
  add(query_603216, "SignatureMethod", newJString(SignatureMethod))
  add(query_603216, "APIVersion", newJString(APIVersion))
  add(query_603216, "Signature", newJString(Signature))
  add(query_603216, "MaxJobs", newJInt(MaxJobs))
  add(query_603216, "Action", newJString(Action))
  add(query_603216, "Marker", newJString(Marker))
  add(query_603216, "Timestamp", newJString(Timestamp))
  add(query_603216, "Operation", newJString(Operation))
  add(query_603216, "SignatureVersion", newJString(SignatureVersion))
  add(query_603216, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603216, "Version", newJString(Version))
  result = call_603215.call(nil, query_603216, nil, nil, nil)

var getListJobs* = Call_GetListJobs_603200(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_603201,
                                        base: "/", url: url_GetListJobs_603202,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_603254 = ref object of OpenApiRestCall_602450
proc url_PostUpdateJob_603256(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateJob_603255(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603257 = query.getOrDefault("SignatureMethod")
  valid_603257 = validateParameter(valid_603257, JString, required = true,
                                 default = nil)
  if valid_603257 != nil:
    section.add "SignatureMethod", valid_603257
  var valid_603258 = query.getOrDefault("Signature")
  valid_603258 = validateParameter(valid_603258, JString, required = true,
                                 default = nil)
  if valid_603258 != nil:
    section.add "Signature", valid_603258
  var valid_603259 = query.getOrDefault("Action")
  valid_603259 = validateParameter(valid_603259, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603259 != nil:
    section.add "Action", valid_603259
  var valid_603260 = query.getOrDefault("Timestamp")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = nil)
  if valid_603260 != nil:
    section.add "Timestamp", valid_603260
  var valid_603261 = query.getOrDefault("Operation")
  valid_603261 = validateParameter(valid_603261, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603261 != nil:
    section.add "Operation", valid_603261
  var valid_603262 = query.getOrDefault("SignatureVersion")
  valid_603262 = validateParameter(valid_603262, JString, required = true,
                                 default = nil)
  if valid_603262 != nil:
    section.add "SignatureVersion", valid_603262
  var valid_603263 = query.getOrDefault("AWSAccessKeyId")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = nil)
  if valid_603263 != nil:
    section.add "AWSAccessKeyId", valid_603263
  var valid_603264 = query.getOrDefault("Version")
  valid_603264 = validateParameter(valid_603264, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603264 != nil:
    section.add "Version", valid_603264
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
  var valid_603265 = formData.getOrDefault("Manifest")
  valid_603265 = validateParameter(valid_603265, JString, required = true,
                                 default = nil)
  if valid_603265 != nil:
    section.add "Manifest", valid_603265
  var valid_603266 = formData.getOrDefault("JobType")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = newJString("Import"))
  if valid_603266 != nil:
    section.add "JobType", valid_603266
  var valid_603267 = formData.getOrDefault("JobId")
  valid_603267 = validateParameter(valid_603267, JString, required = true,
                                 default = nil)
  if valid_603267 != nil:
    section.add "JobId", valid_603267
  var valid_603268 = formData.getOrDefault("ValidateOnly")
  valid_603268 = validateParameter(valid_603268, JBool, required = true, default = nil)
  if valid_603268 != nil:
    section.add "ValidateOnly", valid_603268
  var valid_603269 = formData.getOrDefault("APIVersion")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "APIVersion", valid_603269
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603270: Call_PostUpdateJob_603254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_603270.validator(path, query, header, formData, body)
  let scheme = call_603270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603270.url(scheme.get, call_603270.host, call_603270.base,
                         call_603270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603270, url, valid)

proc call*(call_603271: Call_PostUpdateJob_603254; SignatureMethod: string;
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
  var query_603272 = newJObject()
  var formData_603273 = newJObject()
  add(query_603272, "SignatureMethod", newJString(SignatureMethod))
  add(query_603272, "Signature", newJString(Signature))
  add(formData_603273, "Manifest", newJString(Manifest))
  add(formData_603273, "JobType", newJString(JobType))
  add(query_603272, "Action", newJString(Action))
  add(query_603272, "Timestamp", newJString(Timestamp))
  add(formData_603273, "JobId", newJString(JobId))
  add(query_603272, "Operation", newJString(Operation))
  add(query_603272, "SignatureVersion", newJString(SignatureVersion))
  add(query_603272, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603272, "Version", newJString(Version))
  add(formData_603273, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_603273, "APIVersion", newJString(APIVersion))
  result = call_603271.call(nil, query_603272, nil, formData_603273, nil)

var postUpdateJob* = Call_PostUpdateJob_603254(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_603255, base: "/", url: url_PostUpdateJob_603256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_603235 = ref object of OpenApiRestCall_602450
proc url_GetUpdateJob_603237(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateJob_603236(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603238 = query.getOrDefault("SignatureMethod")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = nil)
  if valid_603238 != nil:
    section.add "SignatureMethod", valid_603238
  var valid_603239 = query.getOrDefault("Manifest")
  valid_603239 = validateParameter(valid_603239, JString, required = true,
                                 default = nil)
  if valid_603239 != nil:
    section.add "Manifest", valid_603239
  var valid_603240 = query.getOrDefault("JobId")
  valid_603240 = validateParameter(valid_603240, JString, required = true,
                                 default = nil)
  if valid_603240 != nil:
    section.add "JobId", valid_603240
  var valid_603241 = query.getOrDefault("APIVersion")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "APIVersion", valid_603241
  var valid_603242 = query.getOrDefault("Signature")
  valid_603242 = validateParameter(valid_603242, JString, required = true,
                                 default = nil)
  if valid_603242 != nil:
    section.add "Signature", valid_603242
  var valid_603243 = query.getOrDefault("Action")
  valid_603243 = validateParameter(valid_603243, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603243 != nil:
    section.add "Action", valid_603243
  var valid_603244 = query.getOrDefault("JobType")
  valid_603244 = validateParameter(valid_603244, JString, required = true,
                                 default = newJString("Import"))
  if valid_603244 != nil:
    section.add "JobType", valid_603244
  var valid_603245 = query.getOrDefault("ValidateOnly")
  valid_603245 = validateParameter(valid_603245, JBool, required = true, default = nil)
  if valid_603245 != nil:
    section.add "ValidateOnly", valid_603245
  var valid_603246 = query.getOrDefault("Timestamp")
  valid_603246 = validateParameter(valid_603246, JString, required = true,
                                 default = nil)
  if valid_603246 != nil:
    section.add "Timestamp", valid_603246
  var valid_603247 = query.getOrDefault("Operation")
  valid_603247 = validateParameter(valid_603247, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603247 != nil:
    section.add "Operation", valid_603247
  var valid_603248 = query.getOrDefault("SignatureVersion")
  valid_603248 = validateParameter(valid_603248, JString, required = true,
                                 default = nil)
  if valid_603248 != nil:
    section.add "SignatureVersion", valid_603248
  var valid_603249 = query.getOrDefault("AWSAccessKeyId")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "AWSAccessKeyId", valid_603249
  var valid_603250 = query.getOrDefault("Version")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603250 != nil:
    section.add "Version", valid_603250
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603251: Call_GetUpdateJob_603235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_603251.validator(path, query, header, formData, body)
  let scheme = call_603251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603251.url(scheme.get, call_603251.host, call_603251.base,
                         call_603251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603251, url, valid)

proc call*(call_603252: Call_GetUpdateJob_603235; SignatureMethod: string;
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
  var query_603253 = newJObject()
  add(query_603253, "SignatureMethod", newJString(SignatureMethod))
  add(query_603253, "Manifest", newJString(Manifest))
  add(query_603253, "JobId", newJString(JobId))
  add(query_603253, "APIVersion", newJString(APIVersion))
  add(query_603253, "Signature", newJString(Signature))
  add(query_603253, "Action", newJString(Action))
  add(query_603253, "JobType", newJString(JobType))
  add(query_603253, "ValidateOnly", newJBool(ValidateOnly))
  add(query_603253, "Timestamp", newJString(Timestamp))
  add(query_603253, "Operation", newJString(Operation))
  add(query_603253, "SignatureVersion", newJString(SignatureVersion))
  add(query_603253, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603253, "Version", newJString(Version))
  result = call_603252.call(nil, query_603253, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_603235(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_603236, base: "/", url: url_GetUpdateJob_603237,
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
