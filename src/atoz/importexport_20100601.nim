
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602417 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602417](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602417): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostCancelJob_603025 = ref object of OpenApiRestCall_602417
proc url_PostCancelJob_603027(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCancelJob_603026(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603028 = query.getOrDefault("SignatureMethod")
  valid_603028 = validateParameter(valid_603028, JString, required = true,
                                 default = nil)
  if valid_603028 != nil:
    section.add "SignatureMethod", valid_603028
  var valid_603029 = query.getOrDefault("Signature")
  valid_603029 = validateParameter(valid_603029, JString, required = true,
                                 default = nil)
  if valid_603029 != nil:
    section.add "Signature", valid_603029
  var valid_603030 = query.getOrDefault("Action")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_603030 != nil:
    section.add "Action", valid_603030
  var valid_603031 = query.getOrDefault("Timestamp")
  valid_603031 = validateParameter(valid_603031, JString, required = true,
                                 default = nil)
  if valid_603031 != nil:
    section.add "Timestamp", valid_603031
  var valid_603032 = query.getOrDefault("Operation")
  valid_603032 = validateParameter(valid_603032, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_603032 != nil:
    section.add "Operation", valid_603032
  var valid_603033 = query.getOrDefault("SignatureVersion")
  valid_603033 = validateParameter(valid_603033, JString, required = true,
                                 default = nil)
  if valid_603033 != nil:
    section.add "SignatureVersion", valid_603033
  var valid_603034 = query.getOrDefault("AWSAccessKeyId")
  valid_603034 = validateParameter(valid_603034, JString, required = true,
                                 default = nil)
  if valid_603034 != nil:
    section.add "AWSAccessKeyId", valid_603034
  var valid_603035 = query.getOrDefault("Version")
  valid_603035 = validateParameter(valid_603035, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603035 != nil:
    section.add "Version", valid_603035
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
  var valid_603036 = formData.getOrDefault("JobId")
  valid_603036 = validateParameter(valid_603036, JString, required = true,
                                 default = nil)
  if valid_603036 != nil:
    section.add "JobId", valid_603036
  var valid_603037 = formData.getOrDefault("APIVersion")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "APIVersion", valid_603037
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603038: Call_PostCancelJob_603025; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_603038.validator(path, query, header, formData, body)
  let scheme = call_603038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603038.url(scheme.get, call_603038.host, call_603038.base,
                         call_603038.route, valid.getOrDefault("path"))
  result = hook(call_603038, url, valid)

proc call*(call_603039: Call_PostCancelJob_603025; SignatureMethod: string;
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
  var query_603040 = newJObject()
  var formData_603041 = newJObject()
  add(query_603040, "SignatureMethod", newJString(SignatureMethod))
  add(query_603040, "Signature", newJString(Signature))
  add(query_603040, "Action", newJString(Action))
  add(query_603040, "Timestamp", newJString(Timestamp))
  add(formData_603041, "JobId", newJString(JobId))
  add(query_603040, "Operation", newJString(Operation))
  add(query_603040, "SignatureVersion", newJString(SignatureVersion))
  add(query_603040, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603040, "Version", newJString(Version))
  add(formData_603041, "APIVersion", newJString(APIVersion))
  result = call_603039.call(nil, query_603040, nil, formData_603041, nil)

var postCancelJob* = Call_PostCancelJob_603025(name: "postCancelJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_PostCancelJob_603026, base: "/", url: url_PostCancelJob_603027,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCancelJob_602754 = ref object of OpenApiRestCall_602417
proc url_GetCancelJob_602756(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCancelJob_602755(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602868 = query.getOrDefault("SignatureMethod")
  valid_602868 = validateParameter(valid_602868, JString, required = true,
                                 default = nil)
  if valid_602868 != nil:
    section.add "SignatureMethod", valid_602868
  var valid_602869 = query.getOrDefault("JobId")
  valid_602869 = validateParameter(valid_602869, JString, required = true,
                                 default = nil)
  if valid_602869 != nil:
    section.add "JobId", valid_602869
  var valid_602870 = query.getOrDefault("APIVersion")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "APIVersion", valid_602870
  var valid_602871 = query.getOrDefault("Signature")
  valid_602871 = validateParameter(valid_602871, JString, required = true,
                                 default = nil)
  if valid_602871 != nil:
    section.add "Signature", valid_602871
  var valid_602885 = query.getOrDefault("Action")
  valid_602885 = validateParameter(valid_602885, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_602885 != nil:
    section.add "Action", valid_602885
  var valid_602886 = query.getOrDefault("Timestamp")
  valid_602886 = validateParameter(valid_602886, JString, required = true,
                                 default = nil)
  if valid_602886 != nil:
    section.add "Timestamp", valid_602886
  var valid_602887 = query.getOrDefault("Operation")
  valid_602887 = validateParameter(valid_602887, JString, required = true,
                                 default = newJString("CancelJob"))
  if valid_602887 != nil:
    section.add "Operation", valid_602887
  var valid_602888 = query.getOrDefault("SignatureVersion")
  valid_602888 = validateParameter(valid_602888, JString, required = true,
                                 default = nil)
  if valid_602888 != nil:
    section.add "SignatureVersion", valid_602888
  var valid_602889 = query.getOrDefault("AWSAccessKeyId")
  valid_602889 = validateParameter(valid_602889, JString, required = true,
                                 default = nil)
  if valid_602889 != nil:
    section.add "AWSAccessKeyId", valid_602889
  var valid_602890 = query.getOrDefault("Version")
  valid_602890 = validateParameter(valid_602890, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_602890 != nil:
    section.add "Version", valid_602890
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602913: Call_GetCancelJob_602754; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a specified job. Only the job owner can cancel it. The operation fails if the job has already started or is complete.
  ## 
  let valid = call_602913.validator(path, query, header, formData, body)
  let scheme = call_602913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602913.url(scheme.get, call_602913.host, call_602913.base,
                         call_602913.route, valid.getOrDefault("path"))
  result = hook(call_602913, url, valid)

proc call*(call_602984: Call_GetCancelJob_602754; SignatureMethod: string;
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
  var query_602985 = newJObject()
  add(query_602985, "SignatureMethod", newJString(SignatureMethod))
  add(query_602985, "JobId", newJString(JobId))
  add(query_602985, "APIVersion", newJString(APIVersion))
  add(query_602985, "Signature", newJString(Signature))
  add(query_602985, "Action", newJString(Action))
  add(query_602985, "Timestamp", newJString(Timestamp))
  add(query_602985, "Operation", newJString(Operation))
  add(query_602985, "SignatureVersion", newJString(SignatureVersion))
  add(query_602985, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_602985, "Version", newJString(Version))
  result = call_602984.call(nil, query_602985, nil, nil, nil)

var getCancelJob* = Call_GetCancelJob_602754(name: "getCancelJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CancelJob&Action=CancelJob",
    validator: validate_GetCancelJob_602755, base: "/", url: url_GetCancelJob_602756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateJob_603061 = ref object of OpenApiRestCall_602417
proc url_PostCreateJob_603063(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateJob_603062(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603064 = query.getOrDefault("SignatureMethod")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = nil)
  if valid_603064 != nil:
    section.add "SignatureMethod", valid_603064
  var valid_603065 = query.getOrDefault("Signature")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = nil)
  if valid_603065 != nil:
    section.add "Signature", valid_603065
  var valid_603066 = query.getOrDefault("Action")
  valid_603066 = validateParameter(valid_603066, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603066 != nil:
    section.add "Action", valid_603066
  var valid_603067 = query.getOrDefault("Timestamp")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = nil)
  if valid_603067 != nil:
    section.add "Timestamp", valid_603067
  var valid_603068 = query.getOrDefault("Operation")
  valid_603068 = validateParameter(valid_603068, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603068 != nil:
    section.add "Operation", valid_603068
  var valid_603069 = query.getOrDefault("SignatureVersion")
  valid_603069 = validateParameter(valid_603069, JString, required = true,
                                 default = nil)
  if valid_603069 != nil:
    section.add "SignatureVersion", valid_603069
  var valid_603070 = query.getOrDefault("AWSAccessKeyId")
  valid_603070 = validateParameter(valid_603070, JString, required = true,
                                 default = nil)
  if valid_603070 != nil:
    section.add "AWSAccessKeyId", valid_603070
  var valid_603071 = query.getOrDefault("Version")
  valid_603071 = validateParameter(valid_603071, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603071 != nil:
    section.add "Version", valid_603071
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
  var valid_603072 = formData.getOrDefault("ManifestAddendum")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "ManifestAddendum", valid_603072
  assert formData != nil,
        "formData argument is necessary due to required `Manifest` field"
  var valid_603073 = formData.getOrDefault("Manifest")
  valid_603073 = validateParameter(valid_603073, JString, required = true,
                                 default = nil)
  if valid_603073 != nil:
    section.add "Manifest", valid_603073
  var valid_603074 = formData.getOrDefault("JobType")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = newJString("Import"))
  if valid_603074 != nil:
    section.add "JobType", valid_603074
  var valid_603075 = formData.getOrDefault("ValidateOnly")
  valid_603075 = validateParameter(valid_603075, JBool, required = true, default = nil)
  if valid_603075 != nil:
    section.add "ValidateOnly", valid_603075
  var valid_603076 = formData.getOrDefault("APIVersion")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "APIVersion", valid_603076
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_PostCreateJob_603061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"))
  result = hook(call_603077, url, valid)

proc call*(call_603078: Call_PostCreateJob_603061; SignatureMethod: string;
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
  var query_603079 = newJObject()
  var formData_603080 = newJObject()
  add(query_603079, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603080, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_603079, "Signature", newJString(Signature))
  add(formData_603080, "Manifest", newJString(Manifest))
  add(formData_603080, "JobType", newJString(JobType))
  add(query_603079, "Action", newJString(Action))
  add(query_603079, "Timestamp", newJString(Timestamp))
  add(query_603079, "Operation", newJString(Operation))
  add(query_603079, "SignatureVersion", newJString(SignatureVersion))
  add(query_603079, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603079, "Version", newJString(Version))
  add(formData_603080, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_603080, "APIVersion", newJString(APIVersion))
  result = call_603078.call(nil, query_603079, nil, formData_603080, nil)

var postCreateJob* = Call_PostCreateJob_603061(name: "postCreateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_PostCreateJob_603062, base: "/", url: url_PostCreateJob_603063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateJob_603042 = ref object of OpenApiRestCall_602417
proc url_GetCreateJob_603044(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateJob_603043(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603045 = query.getOrDefault("SignatureMethod")
  valid_603045 = validateParameter(valid_603045, JString, required = true,
                                 default = nil)
  if valid_603045 != nil:
    section.add "SignatureMethod", valid_603045
  var valid_603046 = query.getOrDefault("Manifest")
  valid_603046 = validateParameter(valid_603046, JString, required = true,
                                 default = nil)
  if valid_603046 != nil:
    section.add "Manifest", valid_603046
  var valid_603047 = query.getOrDefault("APIVersion")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "APIVersion", valid_603047
  var valid_603048 = query.getOrDefault("Signature")
  valid_603048 = validateParameter(valid_603048, JString, required = true,
                                 default = nil)
  if valid_603048 != nil:
    section.add "Signature", valid_603048
  var valid_603049 = query.getOrDefault("Action")
  valid_603049 = validateParameter(valid_603049, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603049 != nil:
    section.add "Action", valid_603049
  var valid_603050 = query.getOrDefault("JobType")
  valid_603050 = validateParameter(valid_603050, JString, required = true,
                                 default = newJString("Import"))
  if valid_603050 != nil:
    section.add "JobType", valid_603050
  var valid_603051 = query.getOrDefault("ValidateOnly")
  valid_603051 = validateParameter(valid_603051, JBool, required = true, default = nil)
  if valid_603051 != nil:
    section.add "ValidateOnly", valid_603051
  var valid_603052 = query.getOrDefault("Timestamp")
  valid_603052 = validateParameter(valid_603052, JString, required = true,
                                 default = nil)
  if valid_603052 != nil:
    section.add "Timestamp", valid_603052
  var valid_603053 = query.getOrDefault("ManifestAddendum")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "ManifestAddendum", valid_603053
  var valid_603054 = query.getOrDefault("Operation")
  valid_603054 = validateParameter(valid_603054, JString, required = true,
                                 default = newJString("CreateJob"))
  if valid_603054 != nil:
    section.add "Operation", valid_603054
  var valid_603055 = query.getOrDefault("SignatureVersion")
  valid_603055 = validateParameter(valid_603055, JString, required = true,
                                 default = nil)
  if valid_603055 != nil:
    section.add "SignatureVersion", valid_603055
  var valid_603056 = query.getOrDefault("AWSAccessKeyId")
  valid_603056 = validateParameter(valid_603056, JString, required = true,
                                 default = nil)
  if valid_603056 != nil:
    section.add "AWSAccessKeyId", valid_603056
  var valid_603057 = query.getOrDefault("Version")
  valid_603057 = validateParameter(valid_603057, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603057 != nil:
    section.add "Version", valid_603057
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_GetCreateJob_603042; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation initiates the process of scheduling an upload or download of your data. You include in the request a manifest that describes the data transfer specifics. The response to the request includes a job ID, which you can use in other operations, a signature that you use to identify your storage device, and the address where you should ship your storage device.
  ## 
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"))
  result = hook(call_603058, url, valid)

proc call*(call_603059: Call_GetCreateJob_603042; SignatureMethod: string;
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
  var query_603060 = newJObject()
  add(query_603060, "SignatureMethod", newJString(SignatureMethod))
  add(query_603060, "Manifest", newJString(Manifest))
  add(query_603060, "APIVersion", newJString(APIVersion))
  add(query_603060, "Signature", newJString(Signature))
  add(query_603060, "Action", newJString(Action))
  add(query_603060, "JobType", newJString(JobType))
  add(query_603060, "ValidateOnly", newJBool(ValidateOnly))
  add(query_603060, "Timestamp", newJString(Timestamp))
  add(query_603060, "ManifestAddendum", newJString(ManifestAddendum))
  add(query_603060, "Operation", newJString(Operation))
  add(query_603060, "SignatureVersion", newJString(SignatureVersion))
  add(query_603060, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603060, "Version", newJString(Version))
  result = call_603059.call(nil, query_603060, nil, nil, nil)

var getCreateJob* = Call_GetCreateJob_603042(name: "getCreateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=CreateJob&Action=CreateJob",
    validator: validate_GetCreateJob_603043, base: "/", url: url_GetCreateJob_603044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetShippingLabel_603107 = ref object of OpenApiRestCall_602417
proc url_PostGetShippingLabel_603109(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetShippingLabel_603108(path: JsonNode; query: JsonNode;
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
  var valid_603110 = query.getOrDefault("SignatureMethod")
  valid_603110 = validateParameter(valid_603110, JString, required = true,
                                 default = nil)
  if valid_603110 != nil:
    section.add "SignatureMethod", valid_603110
  var valid_603111 = query.getOrDefault("Signature")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "Signature", valid_603111
  var valid_603112 = query.getOrDefault("Action")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603112 != nil:
    section.add "Action", valid_603112
  var valid_603113 = query.getOrDefault("Timestamp")
  valid_603113 = validateParameter(valid_603113, JString, required = true,
                                 default = nil)
  if valid_603113 != nil:
    section.add "Timestamp", valid_603113
  var valid_603114 = query.getOrDefault("Operation")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603114 != nil:
    section.add "Operation", valid_603114
  var valid_603115 = query.getOrDefault("SignatureVersion")
  valid_603115 = validateParameter(valid_603115, JString, required = true,
                                 default = nil)
  if valid_603115 != nil:
    section.add "SignatureVersion", valid_603115
  var valid_603116 = query.getOrDefault("AWSAccessKeyId")
  valid_603116 = validateParameter(valid_603116, JString, required = true,
                                 default = nil)
  if valid_603116 != nil:
    section.add "AWSAccessKeyId", valid_603116
  var valid_603117 = query.getOrDefault("Version")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603117 != nil:
    section.add "Version", valid_603117
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
  var valid_603118 = formData.getOrDefault("company")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "company", valid_603118
  var valid_603119 = formData.getOrDefault("stateOrProvince")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "stateOrProvince", valid_603119
  var valid_603120 = formData.getOrDefault("street1")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "street1", valid_603120
  var valid_603121 = formData.getOrDefault("name")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "name", valid_603121
  var valid_603122 = formData.getOrDefault("street3")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "street3", valid_603122
  var valid_603123 = formData.getOrDefault("city")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "city", valid_603123
  var valid_603124 = formData.getOrDefault("postalCode")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "postalCode", valid_603124
  var valid_603125 = formData.getOrDefault("phoneNumber")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "phoneNumber", valid_603125
  var valid_603126 = formData.getOrDefault("street2")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "street2", valid_603126
  var valid_603127 = formData.getOrDefault("country")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "country", valid_603127
  var valid_603128 = formData.getOrDefault("APIVersion")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "APIVersion", valid_603128
  assert formData != nil,
        "formData argument is necessary due to required `jobIds` field"
  var valid_603129 = formData.getOrDefault("jobIds")
  valid_603129 = validateParameter(valid_603129, JArray, required = true, default = nil)
  if valid_603129 != nil:
    section.add "jobIds", valid_603129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603130: Call_PostGetShippingLabel_603107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_603130.validator(path, query, header, formData, body)
  let scheme = call_603130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603130.url(scheme.get, call_603130.host, call_603130.base,
                         call_603130.route, valid.getOrDefault("path"))
  result = hook(call_603130, url, valid)

proc call*(call_603131: Call_PostGetShippingLabel_603107; SignatureMethod: string;
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
  var query_603132 = newJObject()
  var formData_603133 = newJObject()
  add(formData_603133, "company", newJString(company))
  add(query_603132, "SignatureMethod", newJString(SignatureMethod))
  add(formData_603133, "stateOrProvince", newJString(stateOrProvince))
  add(query_603132, "Signature", newJString(Signature))
  add(formData_603133, "street1", newJString(street1))
  add(formData_603133, "name", newJString(name))
  add(formData_603133, "street3", newJString(street3))
  add(query_603132, "Action", newJString(Action))
  add(formData_603133, "city", newJString(city))
  add(query_603132, "Timestamp", newJString(Timestamp))
  add(formData_603133, "postalCode", newJString(postalCode))
  add(query_603132, "Operation", newJString(Operation))
  add(query_603132, "SignatureVersion", newJString(SignatureVersion))
  add(formData_603133, "phoneNumber", newJString(phoneNumber))
  add(query_603132, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(formData_603133, "street2", newJString(street2))
  add(query_603132, "Version", newJString(Version))
  add(formData_603133, "country", newJString(country))
  add(formData_603133, "APIVersion", newJString(APIVersion))
  if jobIds != nil:
    formData_603133.add "jobIds", jobIds
  result = call_603131.call(nil, query_603132, nil, formData_603133, nil)

var postGetShippingLabel* = Call_PostGetShippingLabel_603107(
    name: "postGetShippingLabel", meth: HttpMethod.HttpPost,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_PostGetShippingLabel_603108, base: "/",
    url: url_PostGetShippingLabel_603109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetShippingLabel_603081 = ref object of OpenApiRestCall_602417
proc url_GetGetShippingLabel_603083(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetShippingLabel_603082(path: JsonNode; query: JsonNode;
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
  var valid_603084 = query.getOrDefault("SignatureMethod")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = nil)
  if valid_603084 != nil:
    section.add "SignatureMethod", valid_603084
  var valid_603085 = query.getOrDefault("city")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "city", valid_603085
  var valid_603086 = query.getOrDefault("country")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "country", valid_603086
  var valid_603087 = query.getOrDefault("stateOrProvince")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "stateOrProvince", valid_603087
  var valid_603088 = query.getOrDefault("company")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "company", valid_603088
  var valid_603089 = query.getOrDefault("APIVersion")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "APIVersion", valid_603089
  var valid_603090 = query.getOrDefault("phoneNumber")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "phoneNumber", valid_603090
  var valid_603091 = query.getOrDefault("street1")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "street1", valid_603091
  var valid_603092 = query.getOrDefault("Signature")
  valid_603092 = validateParameter(valid_603092, JString, required = true,
                                 default = nil)
  if valid_603092 != nil:
    section.add "Signature", valid_603092
  var valid_603093 = query.getOrDefault("street3")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "street3", valid_603093
  var valid_603094 = query.getOrDefault("Action")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603094 != nil:
    section.add "Action", valid_603094
  var valid_603095 = query.getOrDefault("name")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "name", valid_603095
  var valid_603096 = query.getOrDefault("Timestamp")
  valid_603096 = validateParameter(valid_603096, JString, required = true,
                                 default = nil)
  if valid_603096 != nil:
    section.add "Timestamp", valid_603096
  var valid_603097 = query.getOrDefault("Operation")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = newJString("GetShippingLabel"))
  if valid_603097 != nil:
    section.add "Operation", valid_603097
  var valid_603098 = query.getOrDefault("SignatureVersion")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = nil)
  if valid_603098 != nil:
    section.add "SignatureVersion", valid_603098
  var valid_603099 = query.getOrDefault("jobIds")
  valid_603099 = validateParameter(valid_603099, JArray, required = true, default = nil)
  if valid_603099 != nil:
    section.add "jobIds", valid_603099
  var valid_603100 = query.getOrDefault("AWSAccessKeyId")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = nil)
  if valid_603100 != nil:
    section.add "AWSAccessKeyId", valid_603100
  var valid_603101 = query.getOrDefault("street2")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "street2", valid_603101
  var valid_603102 = query.getOrDefault("postalCode")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "postalCode", valid_603102
  var valid_603103 = query.getOrDefault("Version")
  valid_603103 = validateParameter(valid_603103, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603103 != nil:
    section.add "Version", valid_603103
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603104: Call_GetGetShippingLabel_603081; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation generates a pre-paid UPS shipping label that you will use to ship your device to AWS for processing.
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"))
  result = hook(call_603104, url, valid)

proc call*(call_603105: Call_GetGetShippingLabel_603081; SignatureMethod: string;
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
  var query_603106 = newJObject()
  add(query_603106, "SignatureMethod", newJString(SignatureMethod))
  add(query_603106, "city", newJString(city))
  add(query_603106, "country", newJString(country))
  add(query_603106, "stateOrProvince", newJString(stateOrProvince))
  add(query_603106, "company", newJString(company))
  add(query_603106, "APIVersion", newJString(APIVersion))
  add(query_603106, "phoneNumber", newJString(phoneNumber))
  add(query_603106, "street1", newJString(street1))
  add(query_603106, "Signature", newJString(Signature))
  add(query_603106, "street3", newJString(street3))
  add(query_603106, "Action", newJString(Action))
  add(query_603106, "name", newJString(name))
  add(query_603106, "Timestamp", newJString(Timestamp))
  add(query_603106, "Operation", newJString(Operation))
  add(query_603106, "SignatureVersion", newJString(SignatureVersion))
  if jobIds != nil:
    query_603106.add "jobIds", jobIds
  add(query_603106, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603106, "street2", newJString(street2))
  add(query_603106, "postalCode", newJString(postalCode))
  add(query_603106, "Version", newJString(Version))
  result = call_603105.call(nil, query_603106, nil, nil, nil)

var getGetShippingLabel* = Call_GetGetShippingLabel_603081(
    name: "getGetShippingLabel", meth: HttpMethod.HttpGet,
    host: "importexport.amazonaws.com",
    route: "/#Operation=GetShippingLabel&Action=GetShippingLabel",
    validator: validate_GetGetShippingLabel_603082, base: "/",
    url: url_GetGetShippingLabel_603083, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostGetStatus_603150 = ref object of OpenApiRestCall_602417
proc url_PostGetStatus_603152(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostGetStatus_603151(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603153 = query.getOrDefault("SignatureMethod")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = nil)
  if valid_603153 != nil:
    section.add "SignatureMethod", valid_603153
  var valid_603154 = query.getOrDefault("Signature")
  valid_603154 = validateParameter(valid_603154, JString, required = true,
                                 default = nil)
  if valid_603154 != nil:
    section.add "Signature", valid_603154
  var valid_603155 = query.getOrDefault("Action")
  valid_603155 = validateParameter(valid_603155, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603155 != nil:
    section.add "Action", valid_603155
  var valid_603156 = query.getOrDefault("Timestamp")
  valid_603156 = validateParameter(valid_603156, JString, required = true,
                                 default = nil)
  if valid_603156 != nil:
    section.add "Timestamp", valid_603156
  var valid_603157 = query.getOrDefault("Operation")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603157 != nil:
    section.add "Operation", valid_603157
  var valid_603158 = query.getOrDefault("SignatureVersion")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "SignatureVersion", valid_603158
  var valid_603159 = query.getOrDefault("AWSAccessKeyId")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = nil)
  if valid_603159 != nil:
    section.add "AWSAccessKeyId", valid_603159
  var valid_603160 = query.getOrDefault("Version")
  valid_603160 = validateParameter(valid_603160, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603160 != nil:
    section.add "Version", valid_603160
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
  var valid_603161 = formData.getOrDefault("JobId")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = nil)
  if valid_603161 != nil:
    section.add "JobId", valid_603161
  var valid_603162 = formData.getOrDefault("APIVersion")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "APIVersion", valid_603162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603163: Call_PostGetStatus_603150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_603163.validator(path, query, header, formData, body)
  let scheme = call_603163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603163.url(scheme.get, call_603163.host, call_603163.base,
                         call_603163.route, valid.getOrDefault("path"))
  result = hook(call_603163, url, valid)

proc call*(call_603164: Call_PostGetStatus_603150; SignatureMethod: string;
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
  var query_603165 = newJObject()
  var formData_603166 = newJObject()
  add(query_603165, "SignatureMethod", newJString(SignatureMethod))
  add(query_603165, "Signature", newJString(Signature))
  add(query_603165, "Action", newJString(Action))
  add(query_603165, "Timestamp", newJString(Timestamp))
  add(formData_603166, "JobId", newJString(JobId))
  add(query_603165, "Operation", newJString(Operation))
  add(query_603165, "SignatureVersion", newJString(SignatureVersion))
  add(query_603165, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603165, "Version", newJString(Version))
  add(formData_603166, "APIVersion", newJString(APIVersion))
  result = call_603164.call(nil, query_603165, nil, formData_603166, nil)

var postGetStatus* = Call_PostGetStatus_603150(name: "postGetStatus",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_PostGetStatus_603151, base: "/", url: url_PostGetStatus_603152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGetStatus_603134 = ref object of OpenApiRestCall_602417
proc url_GetGetStatus_603136(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetGetStatus_603135(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603137 = query.getOrDefault("SignatureMethod")
  valid_603137 = validateParameter(valid_603137, JString, required = true,
                                 default = nil)
  if valid_603137 != nil:
    section.add "SignatureMethod", valid_603137
  var valid_603138 = query.getOrDefault("JobId")
  valid_603138 = validateParameter(valid_603138, JString, required = true,
                                 default = nil)
  if valid_603138 != nil:
    section.add "JobId", valid_603138
  var valid_603139 = query.getOrDefault("APIVersion")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "APIVersion", valid_603139
  var valid_603140 = query.getOrDefault("Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = true,
                                 default = nil)
  if valid_603140 != nil:
    section.add "Signature", valid_603140
  var valid_603141 = query.getOrDefault("Action")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603141 != nil:
    section.add "Action", valid_603141
  var valid_603142 = query.getOrDefault("Timestamp")
  valid_603142 = validateParameter(valid_603142, JString, required = true,
                                 default = nil)
  if valid_603142 != nil:
    section.add "Timestamp", valid_603142
  var valid_603143 = query.getOrDefault("Operation")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = newJString("GetStatus"))
  if valid_603143 != nil:
    section.add "Operation", valid_603143
  var valid_603144 = query.getOrDefault("SignatureVersion")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "SignatureVersion", valid_603144
  var valid_603145 = query.getOrDefault("AWSAccessKeyId")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = nil)
  if valid_603145 != nil:
    section.add "AWSAccessKeyId", valid_603145
  var valid_603146 = query.getOrDefault("Version")
  valid_603146 = validateParameter(valid_603146, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603146 != nil:
    section.add "Version", valid_603146
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603147: Call_GetGetStatus_603134; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job, including where the job is in the processing pipeline, the status of the results, and the signature value associated with the job. You can only return information about jobs you own.
  ## 
  let valid = call_603147.validator(path, query, header, formData, body)
  let scheme = call_603147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603147.url(scheme.get, call_603147.host, call_603147.base,
                         call_603147.route, valid.getOrDefault("path"))
  result = hook(call_603147, url, valid)

proc call*(call_603148: Call_GetGetStatus_603134; SignatureMethod: string;
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
  var query_603149 = newJObject()
  add(query_603149, "SignatureMethod", newJString(SignatureMethod))
  add(query_603149, "JobId", newJString(JobId))
  add(query_603149, "APIVersion", newJString(APIVersion))
  add(query_603149, "Signature", newJString(Signature))
  add(query_603149, "Action", newJString(Action))
  add(query_603149, "Timestamp", newJString(Timestamp))
  add(query_603149, "Operation", newJString(Operation))
  add(query_603149, "SignatureVersion", newJString(SignatureVersion))
  add(query_603149, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603149, "Version", newJString(Version))
  result = call_603148.call(nil, query_603149, nil, nil, nil)

var getGetStatus* = Call_GetGetStatus_603134(name: "getGetStatus",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=GetStatus&Action=GetStatus",
    validator: validate_GetGetStatus_603135, base: "/", url: url_GetGetStatus_603136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListJobs_603184 = ref object of OpenApiRestCall_602417
proc url_PostListJobs_603186(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListJobs_603185(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603187 = query.getOrDefault("SignatureMethod")
  valid_603187 = validateParameter(valid_603187, JString, required = true,
                                 default = nil)
  if valid_603187 != nil:
    section.add "SignatureMethod", valid_603187
  var valid_603188 = query.getOrDefault("Signature")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = nil)
  if valid_603188 != nil:
    section.add "Signature", valid_603188
  var valid_603189 = query.getOrDefault("Action")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603189 != nil:
    section.add "Action", valid_603189
  var valid_603190 = query.getOrDefault("Timestamp")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = nil)
  if valid_603190 != nil:
    section.add "Timestamp", valid_603190
  var valid_603191 = query.getOrDefault("Operation")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603191 != nil:
    section.add "Operation", valid_603191
  var valid_603192 = query.getOrDefault("SignatureVersion")
  valid_603192 = validateParameter(valid_603192, JString, required = true,
                                 default = nil)
  if valid_603192 != nil:
    section.add "SignatureVersion", valid_603192
  var valid_603193 = query.getOrDefault("AWSAccessKeyId")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = nil)
  if valid_603193 != nil:
    section.add "AWSAccessKeyId", valid_603193
  var valid_603194 = query.getOrDefault("Version")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603194 != nil:
    section.add "Version", valid_603194
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
  var valid_603195 = formData.getOrDefault("Marker")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "Marker", valid_603195
  var valid_603196 = formData.getOrDefault("MaxJobs")
  valid_603196 = validateParameter(valid_603196, JInt, required = false, default = nil)
  if valid_603196 != nil:
    section.add "MaxJobs", valid_603196
  var valid_603197 = formData.getOrDefault("APIVersion")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "APIVersion", valid_603197
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603198: Call_PostListJobs_603184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_603198.validator(path, query, header, formData, body)
  let scheme = call_603198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603198.url(scheme.get, call_603198.host, call_603198.base,
                         call_603198.route, valid.getOrDefault("path"))
  result = hook(call_603198, url, valid)

proc call*(call_603199: Call_PostListJobs_603184; SignatureMethod: string;
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
  var query_603200 = newJObject()
  var formData_603201 = newJObject()
  add(query_603200, "SignatureMethod", newJString(SignatureMethod))
  add(query_603200, "Signature", newJString(Signature))
  add(formData_603201, "Marker", newJString(Marker))
  add(query_603200, "Action", newJString(Action))
  add(formData_603201, "MaxJobs", newJInt(MaxJobs))
  add(query_603200, "Timestamp", newJString(Timestamp))
  add(query_603200, "Operation", newJString(Operation))
  add(query_603200, "SignatureVersion", newJString(SignatureVersion))
  add(query_603200, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603200, "Version", newJString(Version))
  add(formData_603201, "APIVersion", newJString(APIVersion))
  result = call_603199.call(nil, query_603200, nil, formData_603201, nil)

var postListJobs* = Call_PostListJobs_603184(name: "postListJobs",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=ListJobs&Action=ListJobs",
    validator: validate_PostListJobs_603185, base: "/", url: url_PostListJobs_603186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListJobs_603167 = ref object of OpenApiRestCall_602417
proc url_GetListJobs_603169(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListJobs_603168(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603170 = query.getOrDefault("SignatureMethod")
  valid_603170 = validateParameter(valid_603170, JString, required = true,
                                 default = nil)
  if valid_603170 != nil:
    section.add "SignatureMethod", valid_603170
  var valid_603171 = query.getOrDefault("APIVersion")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "APIVersion", valid_603171
  var valid_603172 = query.getOrDefault("Signature")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = nil)
  if valid_603172 != nil:
    section.add "Signature", valid_603172
  var valid_603173 = query.getOrDefault("MaxJobs")
  valid_603173 = validateParameter(valid_603173, JInt, required = false, default = nil)
  if valid_603173 != nil:
    section.add "MaxJobs", valid_603173
  var valid_603174 = query.getOrDefault("Action")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603174 != nil:
    section.add "Action", valid_603174
  var valid_603175 = query.getOrDefault("Marker")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Marker", valid_603175
  var valid_603176 = query.getOrDefault("Timestamp")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = nil)
  if valid_603176 != nil:
    section.add "Timestamp", valid_603176
  var valid_603177 = query.getOrDefault("Operation")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = newJString("ListJobs"))
  if valid_603177 != nil:
    section.add "Operation", valid_603177
  var valid_603178 = query.getOrDefault("SignatureVersion")
  valid_603178 = validateParameter(valid_603178, JString, required = true,
                                 default = nil)
  if valid_603178 != nil:
    section.add "SignatureVersion", valid_603178
  var valid_603179 = query.getOrDefault("AWSAccessKeyId")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = nil)
  if valid_603179 != nil:
    section.add "AWSAccessKeyId", valid_603179
  var valid_603180 = query.getOrDefault("Version")
  valid_603180 = validateParameter(valid_603180, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603180 != nil:
    section.add "Version", valid_603180
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603181: Call_GetListJobs_603167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns the jobs associated with the requester. AWS Import/Export lists the jobs in reverse chronological order based on the date of creation. For example if Job Test1 was created 2009Dec30 and Test2 was created 2010Feb05, the ListJobs operation would return Test2 followed by Test1.
  ## 
  let valid = call_603181.validator(path, query, header, formData, body)
  let scheme = call_603181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603181.url(scheme.get, call_603181.host, call_603181.base,
                         call_603181.route, valid.getOrDefault("path"))
  result = hook(call_603181, url, valid)

proc call*(call_603182: Call_GetListJobs_603167; SignatureMethod: string;
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
  var query_603183 = newJObject()
  add(query_603183, "SignatureMethod", newJString(SignatureMethod))
  add(query_603183, "APIVersion", newJString(APIVersion))
  add(query_603183, "Signature", newJString(Signature))
  add(query_603183, "MaxJobs", newJInt(MaxJobs))
  add(query_603183, "Action", newJString(Action))
  add(query_603183, "Marker", newJString(Marker))
  add(query_603183, "Timestamp", newJString(Timestamp))
  add(query_603183, "Operation", newJString(Operation))
  add(query_603183, "SignatureVersion", newJString(SignatureVersion))
  add(query_603183, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603183, "Version", newJString(Version))
  result = call_603182.call(nil, query_603183, nil, nil, nil)

var getListJobs* = Call_GetListJobs_603167(name: "getListJobs",
                                        meth: HttpMethod.HttpGet,
                                        host: "importexport.amazonaws.com", route: "/#Operation=ListJobs&Action=ListJobs",
                                        validator: validate_GetListJobs_603168,
                                        base: "/", url: url_GetListJobs_603169,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateJob_603221 = ref object of OpenApiRestCall_602417
proc url_PostUpdateJob_603223(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateJob_603222(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603224 = query.getOrDefault("SignatureMethod")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = nil)
  if valid_603224 != nil:
    section.add "SignatureMethod", valid_603224
  var valid_603225 = query.getOrDefault("Signature")
  valid_603225 = validateParameter(valid_603225, JString, required = true,
                                 default = nil)
  if valid_603225 != nil:
    section.add "Signature", valid_603225
  var valid_603226 = query.getOrDefault("Action")
  valid_603226 = validateParameter(valid_603226, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603226 != nil:
    section.add "Action", valid_603226
  var valid_603227 = query.getOrDefault("Timestamp")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = nil)
  if valid_603227 != nil:
    section.add "Timestamp", valid_603227
  var valid_603228 = query.getOrDefault("Operation")
  valid_603228 = validateParameter(valid_603228, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603228 != nil:
    section.add "Operation", valid_603228
  var valid_603229 = query.getOrDefault("SignatureVersion")
  valid_603229 = validateParameter(valid_603229, JString, required = true,
                                 default = nil)
  if valid_603229 != nil:
    section.add "SignatureVersion", valid_603229
  var valid_603230 = query.getOrDefault("AWSAccessKeyId")
  valid_603230 = validateParameter(valid_603230, JString, required = true,
                                 default = nil)
  if valid_603230 != nil:
    section.add "AWSAccessKeyId", valid_603230
  var valid_603231 = query.getOrDefault("Version")
  valid_603231 = validateParameter(valid_603231, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603231 != nil:
    section.add "Version", valid_603231
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
  var valid_603232 = formData.getOrDefault("Manifest")
  valid_603232 = validateParameter(valid_603232, JString, required = true,
                                 default = nil)
  if valid_603232 != nil:
    section.add "Manifest", valid_603232
  var valid_603233 = formData.getOrDefault("JobType")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = newJString("Import"))
  if valid_603233 != nil:
    section.add "JobType", valid_603233
  var valid_603234 = formData.getOrDefault("JobId")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = nil)
  if valid_603234 != nil:
    section.add "JobId", valid_603234
  var valid_603235 = formData.getOrDefault("ValidateOnly")
  valid_603235 = validateParameter(valid_603235, JBool, required = true, default = nil)
  if valid_603235 != nil:
    section.add "ValidateOnly", valid_603235
  var valid_603236 = formData.getOrDefault("APIVersion")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "APIVersion", valid_603236
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603237: Call_PostUpdateJob_603221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_603237.validator(path, query, header, formData, body)
  let scheme = call_603237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603237.url(scheme.get, call_603237.host, call_603237.base,
                         call_603237.route, valid.getOrDefault("path"))
  result = hook(call_603237, url, valid)

proc call*(call_603238: Call_PostUpdateJob_603221; SignatureMethod: string;
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
  var query_603239 = newJObject()
  var formData_603240 = newJObject()
  add(query_603239, "SignatureMethod", newJString(SignatureMethod))
  add(query_603239, "Signature", newJString(Signature))
  add(formData_603240, "Manifest", newJString(Manifest))
  add(formData_603240, "JobType", newJString(JobType))
  add(query_603239, "Action", newJString(Action))
  add(query_603239, "Timestamp", newJString(Timestamp))
  add(formData_603240, "JobId", newJString(JobId))
  add(query_603239, "Operation", newJString(Operation))
  add(query_603239, "SignatureVersion", newJString(SignatureVersion))
  add(query_603239, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603239, "Version", newJString(Version))
  add(formData_603240, "ValidateOnly", newJBool(ValidateOnly))
  add(formData_603240, "APIVersion", newJString(APIVersion))
  result = call_603238.call(nil, query_603239, nil, formData_603240, nil)

var postUpdateJob* = Call_PostUpdateJob_603221(name: "postUpdateJob",
    meth: HttpMethod.HttpPost, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_PostUpdateJob_603222, base: "/", url: url_PostUpdateJob_603223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateJob_603202 = ref object of OpenApiRestCall_602417
proc url_GetUpdateJob_603204(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateJob_603203(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_603205 = query.getOrDefault("SignatureMethod")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "SignatureMethod", valid_603205
  var valid_603206 = query.getOrDefault("Manifest")
  valid_603206 = validateParameter(valid_603206, JString, required = true,
                                 default = nil)
  if valid_603206 != nil:
    section.add "Manifest", valid_603206
  var valid_603207 = query.getOrDefault("JobId")
  valid_603207 = validateParameter(valid_603207, JString, required = true,
                                 default = nil)
  if valid_603207 != nil:
    section.add "JobId", valid_603207
  var valid_603208 = query.getOrDefault("APIVersion")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "APIVersion", valid_603208
  var valid_603209 = query.getOrDefault("Signature")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = nil)
  if valid_603209 != nil:
    section.add "Signature", valid_603209
  var valid_603210 = query.getOrDefault("Action")
  valid_603210 = validateParameter(valid_603210, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603210 != nil:
    section.add "Action", valid_603210
  var valid_603211 = query.getOrDefault("JobType")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = newJString("Import"))
  if valid_603211 != nil:
    section.add "JobType", valid_603211
  var valid_603212 = query.getOrDefault("ValidateOnly")
  valid_603212 = validateParameter(valid_603212, JBool, required = true, default = nil)
  if valid_603212 != nil:
    section.add "ValidateOnly", valid_603212
  var valid_603213 = query.getOrDefault("Timestamp")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "Timestamp", valid_603213
  var valid_603214 = query.getOrDefault("Operation")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = newJString("UpdateJob"))
  if valid_603214 != nil:
    section.add "Operation", valid_603214
  var valid_603215 = query.getOrDefault("SignatureVersion")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = nil)
  if valid_603215 != nil:
    section.add "SignatureVersion", valid_603215
  var valid_603216 = query.getOrDefault("AWSAccessKeyId")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "AWSAccessKeyId", valid_603216
  var valid_603217 = query.getOrDefault("Version")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = newJString("2010-06-01"))
  if valid_603217 != nil:
    section.add "Version", valid_603217
  result.add "query", section
  section = newJObject()
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603218: Call_GetUpdateJob_603202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## You use this operation to change the parameters specified in the original manifest file by supplying a new manifest file. The manifest file attached to this request replaces the original manifest file. You can only use the operation after a CreateJob request but before the data transfer starts and you can only use it on jobs you own.
  ## 
  let valid = call_603218.validator(path, query, header, formData, body)
  let scheme = call_603218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603218.url(scheme.get, call_603218.host, call_603218.base,
                         call_603218.route, valid.getOrDefault("path"))
  result = hook(call_603218, url, valid)

proc call*(call_603219: Call_GetUpdateJob_603202; SignatureMethod: string;
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
  var query_603220 = newJObject()
  add(query_603220, "SignatureMethod", newJString(SignatureMethod))
  add(query_603220, "Manifest", newJString(Manifest))
  add(query_603220, "JobId", newJString(JobId))
  add(query_603220, "APIVersion", newJString(APIVersion))
  add(query_603220, "Signature", newJString(Signature))
  add(query_603220, "Action", newJString(Action))
  add(query_603220, "JobType", newJString(JobType))
  add(query_603220, "ValidateOnly", newJBool(ValidateOnly))
  add(query_603220, "Timestamp", newJString(Timestamp))
  add(query_603220, "Operation", newJString(Operation))
  add(query_603220, "SignatureVersion", newJString(SignatureVersion))
  add(query_603220, "AWSAccessKeyId", newJString(AWSAccessKeyId))
  add(query_603220, "Version", newJString(Version))
  result = call_603219.call(nil, query_603220, nil, nil, nil)

var getUpdateJob* = Call_GetUpdateJob_603202(name: "getUpdateJob",
    meth: HttpMethod.HttpGet, host: "importexport.amazonaws.com",
    route: "/#Operation=UpdateJob&Action=UpdateJob",
    validator: validate_GetUpdateJob_603203, base: "/", url: url_GetUpdateJob_603204,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
