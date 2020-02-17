
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Data Exchange
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>AWS Data Exchange is a service that makes it easy for AWS customers to exchange data in the cloud. You can use the AWS Data Exchange APIs to create, update, manage, and access file-based data set in the AWS Cloud.</p><p>As a subscriber, you can view and access the data sets that you have an entitlement to through a subscription. You can use the APIS to download or copy your entitled data sets to Amazon S3 for use across a variety of AWS analytics and machine learning services.</p><p>As a provider, you can create and manage your data sets that you would like to publish to a product. Being able to package and provide your data sets into products requires a few steps to determine eligibility. For more information, visit the AWS Data Exchange User Guide.</p><p>A data set is a collection of data that can be changed or updated over time. Data sets can be updated using revisions, which represent a new version or incremental change to a data set.  A revision contains one or more assets. An asset in AWS Data Exchange is a piece of data that can be stored as an Amazon S3 object. The asset can be a structured data file, an image file, or some other data file. Jobs are asynchronous import or export operations used to create or copy assets.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/dataexchange/
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com", "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
                           "us-west-2": "dataexchange.us-west-2.amazonaws.com",
                           "eu-west-2": "dataexchange.eu-west-2.amazonaws.com", "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com", "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
                           "us-east-2": "dataexchange.us-east-2.amazonaws.com",
                           "us-east-1": "dataexchange.us-east-1.amazonaws.com", "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "dataexchange.ap-south-1.amazonaws.com", "eu-north-1": "dataexchange.eu-north-1.amazonaws.com", "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
                           "us-west-1": "dataexchange.us-west-1.amazonaws.com", "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "dataexchange.eu-west-3.amazonaws.com", "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
                           "eu-west-1": "dataexchange.eu-west-1.amazonaws.com", "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com", "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com", "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "dataexchange.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "dataexchange.ap-southeast-1.amazonaws.com",
      "us-west-2": "dataexchange.us-west-2.amazonaws.com",
      "eu-west-2": "dataexchange.eu-west-2.amazonaws.com",
      "ap-northeast-3": "dataexchange.ap-northeast-3.amazonaws.com",
      "eu-central-1": "dataexchange.eu-central-1.amazonaws.com",
      "us-east-2": "dataexchange.us-east-2.amazonaws.com",
      "us-east-1": "dataexchange.us-east-1.amazonaws.com",
      "cn-northwest-1": "dataexchange.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "dataexchange.ap-south-1.amazonaws.com",
      "eu-north-1": "dataexchange.eu-north-1.amazonaws.com",
      "ap-northeast-2": "dataexchange.ap-northeast-2.amazonaws.com",
      "us-west-1": "dataexchange.us-west-1.amazonaws.com",
      "us-gov-east-1": "dataexchange.us-gov-east-1.amazonaws.com",
      "eu-west-3": "dataexchange.eu-west-3.amazonaws.com",
      "cn-north-1": "dataexchange.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "dataexchange.sa-east-1.amazonaws.com",
      "eu-west-1": "dataexchange.eu-west-1.amazonaws.com",
      "us-gov-west-1": "dataexchange.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "dataexchange.ap-southeast-2.amazonaws.com",
      "ca-central-1": "dataexchange.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "dataexchange"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_GetJob_610996 = ref object of OpenApiRestCall_610658
proc url_GetJob_610998(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetJob_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_611124 = path.getOrDefault("JobId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "JobId", valid_611124
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611125 = header.getOrDefault("X-Amz-Signature")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "X-Amz-Signature", valid_611125
  var valid_611126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Content-Sha256", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Date")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Date", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Credential")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Credential", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Security-Token")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Security-Token", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Algorithm")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Algorithm", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-SignedHeaders", valid_611131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611154: Call_GetJob_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a job.
  ## 
  let valid = call_611154.validator(path, query, header, formData, body)
  let scheme = call_611154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611154.url(scheme.get, call_611154.host, call_611154.base,
                         call_611154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611154, url, valid)

proc call*(call_611225: Call_GetJob_610996; JobId: string): Recallable =
  ## getJob
  ## This operation returns information about a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_611226 = newJObject()
  add(path_611226, "JobId", newJString(JobId))
  result = call_611225.call(path_611226, nil, nil, nil, nil)

var getJob* = Call_GetJob_610996(name: "getJob", meth: HttpMethod.HttpGet,
                              host: "dataexchange.amazonaws.com",
                              route: "/v1/jobs/{JobId}",
                              validator: validate_GetJob_610997, base: "/",
                              url: url_GetJob_610998,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartJob_611280 = ref object of OpenApiRestCall_610658
proc url_StartJob_611282(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartJob_611281(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation starts a job.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_611283 = path.getOrDefault("JobId")
  valid_611283 = validateParameter(valid_611283, JString, required = true,
                                 default = nil)
  if valid_611283 != nil:
    section.add "JobId", valid_611283
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611284 = header.getOrDefault("X-Amz-Signature")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Signature", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Content-Sha256", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Date")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Date", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Credential")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Credential", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-Security-Token")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-Security-Token", valid_611288
  var valid_611289 = header.getOrDefault("X-Amz-Algorithm")
  valid_611289 = validateParameter(valid_611289, JString, required = false,
                                 default = nil)
  if valid_611289 != nil:
    section.add "X-Amz-Algorithm", valid_611289
  var valid_611290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-SignedHeaders", valid_611290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611291: Call_StartJob_611280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation starts a job.
  ## 
  let valid = call_611291.validator(path, query, header, formData, body)
  let scheme = call_611291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611291.url(scheme.get, call_611291.host, call_611291.base,
                         call_611291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611291, url, valid)

proc call*(call_611292: Call_StartJob_611280; JobId: string): Recallable =
  ## startJob
  ## This operation starts a job.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_611293 = newJObject()
  add(path_611293, "JobId", newJString(JobId))
  result = call_611292.call(path_611293, nil, nil, nil, nil)

var startJob* = Call_StartJob_611280(name: "startJob", meth: HttpMethod.HttpPatch,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs/{JobId}",
                                  validator: validate_StartJob_611281, base: "/",
                                  url: url_StartJob_611282,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_611266 = ref object of OpenApiRestCall_610658
proc url_CancelJob_611268(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "JobId" in path, "`JobId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/jobs/"),
               (kind: VariableSegment, value: "JobId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelJob_611267(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   JobId: JString (required)
  ##        : The unique identifier for a job.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `JobId` field"
  var valid_611269 = path.getOrDefault("JobId")
  valid_611269 = validateParameter(valid_611269, JString, required = true,
                                 default = nil)
  if valid_611269 != nil:
    section.add "JobId", valid_611269
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611270 = header.getOrDefault("X-Amz-Signature")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Signature", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Content-Sha256", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Date")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Date", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Credential")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Credential", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Security-Token")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Security-Token", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Algorithm")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Algorithm", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-SignedHeaders", valid_611276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611277: Call_CancelJob_611266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ## 
  let valid = call_611277.validator(path, query, header, formData, body)
  let scheme = call_611277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611277.url(scheme.get, call_611277.host, call_611277.base,
                         call_611277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611277, url, valid)

proc call*(call_611278: Call_CancelJob_611266; JobId: string): Recallable =
  ## cancelJob
  ## This operation cancels a job. Jobs can be cancelled only when they are in the WAITING state.
  ##   JobId: string (required)
  ##        : The unique identifier for a job.
  var path_611279 = newJObject()
  add(path_611279, "JobId", newJString(JobId))
  result = call_611278.call(path_611279, nil, nil, nil, nil)

var cancelJob* = Call_CancelJob_611266(name: "cancelJob",
                                    meth: HttpMethod.HttpDelete,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs/{JobId}",
                                    validator: validate_CancelJob_611267,
                                    base: "/", url: url_CancelJob_611268,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_611312 = ref object of OpenApiRestCall_610658
proc url_CreateDataSet_611314(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataSet_611313(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation creates a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611315 = header.getOrDefault("X-Amz-Signature")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Signature", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Content-Sha256", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-Date")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-Date", valid_611317
  var valid_611318 = header.getOrDefault("X-Amz-Credential")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "X-Amz-Credential", valid_611318
  var valid_611319 = header.getOrDefault("X-Amz-Security-Token")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "X-Amz-Security-Token", valid_611319
  var valid_611320 = header.getOrDefault("X-Amz-Algorithm")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "X-Amz-Algorithm", valid_611320
  var valid_611321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-SignedHeaders", valid_611321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611323: Call_CreateDataSet_611312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a data set.
  ## 
  let valid = call_611323.validator(path, query, header, formData, body)
  let scheme = call_611323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611323.url(scheme.get, call_611323.host, call_611323.base,
                         call_611323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611323, url, valid)

proc call*(call_611324: Call_CreateDataSet_611312; body: JsonNode): Recallable =
  ## createDataSet
  ## This operation creates a data set.
  ##   body: JObject (required)
  var body_611325 = newJObject()
  if body != nil:
    body_611325 = body
  result = call_611324.call(nil, nil, nil, nil, body_611325)

var createDataSet* = Call_CreateDataSet_611312(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_CreateDataSet_611313, base: "/",
    url: url_CreateDataSet_611314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_611294 = ref object of OpenApiRestCall_610658
proc url_ListDataSets_611296(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataSets_611295(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   origin: JString
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_611297 = query.getOrDefault("nextToken")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "nextToken", valid_611297
  var valid_611298 = query.getOrDefault("MaxResults")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "MaxResults", valid_611298
  var valid_611299 = query.getOrDefault("origin")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "origin", valid_611299
  var valid_611300 = query.getOrDefault("NextToken")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "NextToken", valid_611300
  var valid_611301 = query.getOrDefault("maxResults")
  valid_611301 = validateParameter(valid_611301, JInt, required = false, default = nil)
  if valid_611301 != nil:
    section.add "maxResults", valid_611301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611302 = header.getOrDefault("X-Amz-Signature")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-Signature", valid_611302
  var valid_611303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611303 = validateParameter(valid_611303, JString, required = false,
                                 default = nil)
  if valid_611303 != nil:
    section.add "X-Amz-Content-Sha256", valid_611303
  var valid_611304 = header.getOrDefault("X-Amz-Date")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "X-Amz-Date", valid_611304
  var valid_611305 = header.getOrDefault("X-Amz-Credential")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "X-Amz-Credential", valid_611305
  var valid_611306 = header.getOrDefault("X-Amz-Security-Token")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "X-Amz-Security-Token", valid_611306
  var valid_611307 = header.getOrDefault("X-Amz-Algorithm")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Algorithm", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-SignedHeaders", valid_611308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611309: Call_ListDataSets_611294; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ## 
  let valid = call_611309.validator(path, query, header, formData, body)
  let scheme = call_611309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611309.url(scheme.get, call_611309.host, call_611309.base,
                         call_611309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611309, url, valid)

proc call*(call_611310: Call_ListDataSets_611294; nextToken: string = "";
          MaxResults: string = ""; origin: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDataSets
  ## This operation lists your data sets. When listing by origin OWNED, results are sorted by CreatedAt in descending order. When listing by origin ENTITLED, there is no order and the maxResults parameter is ignored.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   origin: string
  ##         : A property that defines the data set as OWNED by the account (for providers) or ENTITLED to the account (for subscribers).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var query_611311 = newJObject()
  add(query_611311, "nextToken", newJString(nextToken))
  add(query_611311, "MaxResults", newJString(MaxResults))
  add(query_611311, "origin", newJString(origin))
  add(query_611311, "NextToken", newJString(NextToken))
  add(query_611311, "maxResults", newJInt(maxResults))
  result = call_611310.call(nil, query_611311, nil, nil, nil)

var listDataSets* = Call_ListDataSets_611294(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets", validator: validate_ListDataSets_611295, base: "/",
    url: url_ListDataSets_611296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_611345 = ref object of OpenApiRestCall_610658
proc url_CreateJob_611347(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateJob_611346(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation creates a job.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611348 = header.getOrDefault("X-Amz-Signature")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Signature", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Content-Sha256", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Date")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Date", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-Credential")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-Credential", valid_611351
  var valid_611352 = header.getOrDefault("X-Amz-Security-Token")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Security-Token", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Algorithm")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Algorithm", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-SignedHeaders", valid_611354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611356: Call_CreateJob_611345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a job.
  ## 
  let valid = call_611356.validator(path, query, header, formData, body)
  let scheme = call_611356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611356.url(scheme.get, call_611356.host, call_611356.base,
                         call_611356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611356, url, valid)

proc call*(call_611357: Call_CreateJob_611345; body: JsonNode): Recallable =
  ## createJob
  ## This operation creates a job.
  ##   body: JObject (required)
  var body_611358 = newJObject()
  if body != nil:
    body_611358 = body
  result = call_611357.call(nil, nil, nil, nil, body_611358)

var createJob* = Call_CreateJob_611345(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "dataexchange.amazonaws.com",
                                    route: "/v1/jobs",
                                    validator: validate_CreateJob_611346,
                                    base: "/", url: url_CreateJob_611347,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_611326 = ref object of OpenApiRestCall_610658
proc url_ListJobs_611328(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListJobs_611327(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   dataSetId: JString
  ##            : The unique identifier for a data set.
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   revisionId: JString
  ##             : The unique identifier for a revision.
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_611329 = query.getOrDefault("dataSetId")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "dataSetId", valid_611329
  var valid_611330 = query.getOrDefault("nextToken")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "nextToken", valid_611330
  var valid_611331 = query.getOrDefault("MaxResults")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "MaxResults", valid_611331
  var valid_611332 = query.getOrDefault("NextToken")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "NextToken", valid_611332
  var valid_611333 = query.getOrDefault("revisionId")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "revisionId", valid_611333
  var valid_611334 = query.getOrDefault("maxResults")
  valid_611334 = validateParameter(valid_611334, JInt, required = false, default = nil)
  if valid_611334 != nil:
    section.add "maxResults", valid_611334
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611335 = header.getOrDefault("X-Amz-Signature")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Signature", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-Content-Sha256", valid_611336
  var valid_611337 = header.getOrDefault("X-Amz-Date")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Date", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Credential")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Credential", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Security-Token")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Security-Token", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Algorithm")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Algorithm", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-SignedHeaders", valid_611341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611342: Call_ListJobs_611326; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ## 
  let valid = call_611342.validator(path, query, header, formData, body)
  let scheme = call_611342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611342.url(scheme.get, call_611342.host, call_611342.base,
                         call_611342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611342, url, valid)

proc call*(call_611343: Call_ListJobs_611326; dataSetId: string = "";
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          revisionId: string = ""; maxResults: int = 0): Recallable =
  ## listJobs
  ## This operation lists your jobs sorted by CreatedAt in descending order.
  ##   dataSetId: string
  ##            : The unique identifier for a data set.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   revisionId: string
  ##             : The unique identifier for a revision.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var query_611344 = newJObject()
  add(query_611344, "dataSetId", newJString(dataSetId))
  add(query_611344, "nextToken", newJString(nextToken))
  add(query_611344, "MaxResults", newJString(MaxResults))
  add(query_611344, "NextToken", newJString(NextToken))
  add(query_611344, "revisionId", newJString(revisionId))
  add(query_611344, "maxResults", newJInt(maxResults))
  result = call_611343.call(nil, query_611344, nil, nil, nil)

var listJobs* = Call_ListJobs_611326(name: "listJobs", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com",
                                  route: "/v1/jobs", validator: validate_ListJobs_611327,
                                  base: "/", url: url_ListJobs_611328,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRevision_611378 = ref object of OpenApiRestCall_610658
proc url_CreateRevision_611380(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateRevision_611379(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation creates a revision for a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_611381 = path.getOrDefault("DataSetId")
  valid_611381 = validateParameter(valid_611381, JString, required = true,
                                 default = nil)
  if valid_611381 != nil:
    section.add "DataSetId", valid_611381
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611382 = header.getOrDefault("X-Amz-Signature")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Signature", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Content-Sha256", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Date")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Date", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Credential")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Credential", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Security-Token")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Security-Token", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Algorithm")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Algorithm", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-SignedHeaders", valid_611388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611390: Call_CreateRevision_611378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation creates a revision for a data set.
  ## 
  let valid = call_611390.validator(path, query, header, formData, body)
  let scheme = call_611390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611390.url(scheme.get, call_611390.host, call_611390.base,
                         call_611390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611390, url, valid)

proc call*(call_611391: Call_CreateRevision_611378; DataSetId: string; body: JsonNode): Recallable =
  ## createRevision
  ## This operation creates a revision for a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_611392 = newJObject()
  var body_611393 = newJObject()
  add(path_611392, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_611393 = body
  result = call_611391.call(path_611392, nil, nil, nil, body_611393)

var createRevision* = Call_CreateRevision_611378(name: "createRevision",
    meth: HttpMethod.HttpPost, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_CreateRevision_611379, base: "/", url: url_CreateRevision_611380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSetRevisions_611359 = ref object of OpenApiRestCall_610658
proc url_ListDataSetRevisions_611361(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSetRevisions_611360(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_611362 = path.getOrDefault("DataSetId")
  valid_611362 = validateParameter(valid_611362, JString, required = true,
                                 default = nil)
  if valid_611362 != nil:
    section.add "DataSetId", valid_611362
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_611363 = query.getOrDefault("nextToken")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "nextToken", valid_611363
  var valid_611364 = query.getOrDefault("MaxResults")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "MaxResults", valid_611364
  var valid_611365 = query.getOrDefault("NextToken")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "NextToken", valid_611365
  var valid_611366 = query.getOrDefault("maxResults")
  valid_611366 = validateParameter(valid_611366, JInt, required = false, default = nil)
  if valid_611366 != nil:
    section.add "maxResults", valid_611366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611367 = header.getOrDefault("X-Amz-Signature")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Signature", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Content-Sha256", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Date")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Date", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Credential")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Credential", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Security-Token")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Security-Token", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Algorithm")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Algorithm", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-SignedHeaders", valid_611373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611374: Call_ListDataSetRevisions_611359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ## 
  let valid = call_611374.validator(path, query, header, formData, body)
  let scheme = call_611374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611374.url(scheme.get, call_611374.host, call_611374.base,
                         call_611374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611374, url, valid)

proc call*(call_611375: Call_ListDataSetRevisions_611359; DataSetId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listDataSetRevisions
  ## This operation lists a data set's revisions sorted by CreatedAt in descending order.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var path_611376 = newJObject()
  var query_611377 = newJObject()
  add(query_611377, "nextToken", newJString(nextToken))
  add(query_611377, "MaxResults", newJString(MaxResults))
  add(query_611377, "NextToken", newJString(NextToken))
  add(path_611376, "DataSetId", newJString(DataSetId))
  add(query_611377, "maxResults", newJInt(maxResults))
  result = call_611375.call(path_611376, query_611377, nil, nil, nil)

var listDataSetRevisions* = Call_ListDataSetRevisions_611359(
    name: "listDataSetRevisions", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions",
    validator: validate_ListDataSetRevisions_611360, base: "/",
    url: url_ListDataSetRevisions_611361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAsset_611394 = ref object of OpenApiRestCall_610658
proc url_GetAsset_611396(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAsset_611395(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_611397 = path.getOrDefault("RevisionId")
  valid_611397 = validateParameter(valid_611397, JString, required = true,
                                 default = nil)
  if valid_611397 != nil:
    section.add "RevisionId", valid_611397
  var valid_611398 = path.getOrDefault("DataSetId")
  valid_611398 = validateParameter(valid_611398, JString, required = true,
                                 default = nil)
  if valid_611398 != nil:
    section.add "DataSetId", valid_611398
  var valid_611399 = path.getOrDefault("AssetId")
  valid_611399 = validateParameter(valid_611399, JString, required = true,
                                 default = nil)
  if valid_611399 != nil:
    section.add "AssetId", valid_611399
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611400 = header.getOrDefault("X-Amz-Signature")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Signature", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Content-Sha256", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Date")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Date", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Credential")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Credential", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Security-Token")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Security-Token", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Algorithm")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Algorithm", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-SignedHeaders", valid_611406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611407: Call_GetAsset_611394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about an asset.
  ## 
  let valid = call_611407.validator(path, query, header, formData, body)
  let scheme = call_611407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611407.url(scheme.get, call_611407.host, call_611407.base,
                         call_611407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611407, url, valid)

proc call*(call_611408: Call_GetAsset_611394; RevisionId: string; DataSetId: string;
          AssetId: string): Recallable =
  ## getAsset
  ## This operation returns information about an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_611409 = newJObject()
  add(path_611409, "RevisionId", newJString(RevisionId))
  add(path_611409, "DataSetId", newJString(DataSetId))
  add(path_611409, "AssetId", newJString(AssetId))
  result = call_611408.call(path_611409, nil, nil, nil, nil)

var getAsset* = Call_GetAsset_611394(name: "getAsset", meth: HttpMethod.HttpGet,
                                  host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                  validator: validate_GetAsset_611395, base: "/",
                                  url: url_GetAsset_611396,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAsset_611426 = ref object of OpenApiRestCall_610658
proc url_UpdateAsset_611428(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAsset_611427(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation updates an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_611429 = path.getOrDefault("RevisionId")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "RevisionId", valid_611429
  var valid_611430 = path.getOrDefault("DataSetId")
  valid_611430 = validateParameter(valid_611430, JString, required = true,
                                 default = nil)
  if valid_611430 != nil:
    section.add "DataSetId", valid_611430
  var valid_611431 = path.getOrDefault("AssetId")
  valid_611431 = validateParameter(valid_611431, JString, required = true,
                                 default = nil)
  if valid_611431 != nil:
    section.add "AssetId", valid_611431
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611432 = header.getOrDefault("X-Amz-Signature")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Signature", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Content-Sha256", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Date")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Date", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Credential")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Credential", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Security-Token")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Security-Token", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Algorithm")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Algorithm", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-SignedHeaders", valid_611438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611440: Call_UpdateAsset_611426; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates an asset.
  ## 
  let valid = call_611440.validator(path, query, header, formData, body)
  let scheme = call_611440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611440.url(scheme.get, call_611440.host, call_611440.base,
                         call_611440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611440, url, valid)

proc call*(call_611441: Call_UpdateAsset_611426; RevisionId: string;
          DataSetId: string; body: JsonNode; AssetId: string): Recallable =
  ## updateAsset
  ## This operation updates an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_611442 = newJObject()
  var body_611443 = newJObject()
  add(path_611442, "RevisionId", newJString(RevisionId))
  add(path_611442, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_611443 = body
  add(path_611442, "AssetId", newJString(AssetId))
  result = call_611441.call(path_611442, nil, nil, nil, body_611443)

var updateAsset* = Call_UpdateAsset_611426(name: "updateAsset",
                                        meth: HttpMethod.HttpPatch,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_UpdateAsset_611427,
                                        base: "/", url: url_UpdateAsset_611428,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAsset_611410 = ref object of OpenApiRestCall_610658
proc url_DeleteAsset_611412(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  assert "AssetId" in path, "`AssetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets/"),
               (kind: VariableSegment, value: "AssetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAsset_611411(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation deletes an asset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: JString (required)
  ##          : The unique identifier for an asset.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_611413 = path.getOrDefault("RevisionId")
  valid_611413 = validateParameter(valid_611413, JString, required = true,
                                 default = nil)
  if valid_611413 != nil:
    section.add "RevisionId", valid_611413
  var valid_611414 = path.getOrDefault("DataSetId")
  valid_611414 = validateParameter(valid_611414, JString, required = true,
                                 default = nil)
  if valid_611414 != nil:
    section.add "DataSetId", valid_611414
  var valid_611415 = path.getOrDefault("AssetId")
  valid_611415 = validateParameter(valid_611415, JString, required = true,
                                 default = nil)
  if valid_611415 != nil:
    section.add "AssetId", valid_611415
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611416 = header.getOrDefault("X-Amz-Signature")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Signature", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Content-Sha256", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Date")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Date", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Credential")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Credential", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Security-Token")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Security-Token", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Algorithm")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Algorithm", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-SignedHeaders", valid_611422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611423: Call_DeleteAsset_611410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes an asset.
  ## 
  let valid = call_611423.validator(path, query, header, formData, body)
  let scheme = call_611423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611423.url(scheme.get, call_611423.host, call_611423.base,
                         call_611423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611423, url, valid)

proc call*(call_611424: Call_DeleteAsset_611410; RevisionId: string;
          DataSetId: string; AssetId: string): Recallable =
  ## deleteAsset
  ## This operation deletes an asset.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   AssetId: string (required)
  ##          : The unique identifier for an asset.
  var path_611425 = newJObject()
  add(path_611425, "RevisionId", newJString(RevisionId))
  add(path_611425, "DataSetId", newJString(DataSetId))
  add(path_611425, "AssetId", newJString(AssetId))
  result = call_611424.call(path_611425, nil, nil, nil, nil)

var deleteAsset* = Call_DeleteAsset_611410(name: "deleteAsset",
                                        meth: HttpMethod.HttpDelete,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets/{AssetId}",
                                        validator: validate_DeleteAsset_611411,
                                        base: "/", url: url_DeleteAsset_611412,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataSet_611444 = ref object of OpenApiRestCall_610658
proc url_GetDataSet_611446(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataSet_611445(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_611447 = path.getOrDefault("DataSetId")
  valid_611447 = validateParameter(valid_611447, JString, required = true,
                                 default = nil)
  if valid_611447 != nil:
    section.add "DataSetId", valid_611447
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611448 = header.getOrDefault("X-Amz-Signature")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Signature", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Content-Sha256", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Date")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Date", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Credential")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Credential", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Security-Token")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Security-Token", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Algorithm")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Algorithm", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-SignedHeaders", valid_611454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611455: Call_GetDataSet_611444; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a data set.
  ## 
  let valid = call_611455.validator(path, query, header, formData, body)
  let scheme = call_611455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611455.url(scheme.get, call_611455.host, call_611455.base,
                         call_611455.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611455, url, valid)

proc call*(call_611456: Call_GetDataSet_611444; DataSetId: string): Recallable =
  ## getDataSet
  ## This operation returns information about a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_611457 = newJObject()
  add(path_611457, "DataSetId", newJString(DataSetId))
  result = call_611456.call(path_611457, nil, nil, nil, nil)

var getDataSet* = Call_GetDataSet_611444(name: "getDataSet",
                                      meth: HttpMethod.HttpGet,
                                      host: "dataexchange.amazonaws.com",
                                      route: "/v1/data-sets/{DataSetId}",
                                      validator: validate_GetDataSet_611445,
                                      base: "/", url: url_GetDataSet_611446,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_611472 = ref object of OpenApiRestCall_610658
proc url_UpdateDataSet_611474(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_611473(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation updates a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_611475 = path.getOrDefault("DataSetId")
  valid_611475 = validateParameter(valid_611475, JString, required = true,
                                 default = nil)
  if valid_611475 != nil:
    section.add "DataSetId", valid_611475
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611476 = header.getOrDefault("X-Amz-Signature")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Signature", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Content-Sha256", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Date")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Date", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Credential")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Credential", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Security-Token")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Security-Token", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Algorithm")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Algorithm", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-SignedHeaders", valid_611482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611484: Call_UpdateDataSet_611472; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a data set.
  ## 
  let valid = call_611484.validator(path, query, header, formData, body)
  let scheme = call_611484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611484.url(scheme.get, call_611484.host, call_611484.base,
                         call_611484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611484, url, valid)

proc call*(call_611485: Call_UpdateDataSet_611472; DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## This operation updates a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_611486 = newJObject()
  var body_611487 = newJObject()
  add(path_611486, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_611487 = body
  result = call_611485.call(path_611486, nil, nil, nil, body_611487)

var updateDataSet* = Call_UpdateDataSet_611472(name: "updateDataSet",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_UpdateDataSet_611473,
    base: "/", url: url_UpdateDataSet_611474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_611458 = ref object of OpenApiRestCall_610658
proc url_DeleteDataSet_611460(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_611459(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation deletes a data set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `DataSetId` field"
  var valid_611461 = path.getOrDefault("DataSetId")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = nil)
  if valid_611461 != nil:
    section.add "DataSetId", valid_611461
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611462 = header.getOrDefault("X-Amz-Signature")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Signature", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Content-Sha256", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Date")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Date", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Credential")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Credential", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Security-Token")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Security-Token", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Algorithm")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Algorithm", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-SignedHeaders", valid_611468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611469: Call_DeleteDataSet_611458; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a data set.
  ## 
  let valid = call_611469.validator(path, query, header, formData, body)
  let scheme = call_611469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611469.url(scheme.get, call_611469.host, call_611469.base,
                         call_611469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611469, url, valid)

proc call*(call_611470: Call_DeleteDataSet_611458; DataSetId: string): Recallable =
  ## deleteDataSet
  ## This operation deletes a data set.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_611471 = newJObject()
  add(path_611471, "DataSetId", newJString(DataSetId))
  result = call_611470.call(path_611471, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_611458(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}", validator: validate_DeleteDataSet_611459,
    base: "/", url: url_DeleteDataSet_611460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevision_611488 = ref object of OpenApiRestCall_610658
proc url_GetRevision_611490(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetRevision_611489(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation returns information about a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_611491 = path.getOrDefault("RevisionId")
  valid_611491 = validateParameter(valid_611491, JString, required = true,
                                 default = nil)
  if valid_611491 != nil:
    section.add "RevisionId", valid_611491
  var valid_611492 = path.getOrDefault("DataSetId")
  valid_611492 = validateParameter(valid_611492, JString, required = true,
                                 default = nil)
  if valid_611492 != nil:
    section.add "DataSetId", valid_611492
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611493 = header.getOrDefault("X-Amz-Signature")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Signature", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Content-Sha256", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Date")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Date", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Credential")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Credential", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Security-Token")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Security-Token", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Algorithm")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Algorithm", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-SignedHeaders", valid_611499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611500: Call_GetRevision_611488; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation returns information about a revision.
  ## 
  let valid = call_611500.validator(path, query, header, formData, body)
  let scheme = call_611500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611500.url(scheme.get, call_611500.host, call_611500.base,
                         call_611500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611500, url, valid)

proc call*(call_611501: Call_GetRevision_611488; RevisionId: string;
          DataSetId: string): Recallable =
  ## getRevision
  ## This operation returns information about a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_611502 = newJObject()
  add(path_611502, "RevisionId", newJString(RevisionId))
  add(path_611502, "DataSetId", newJString(DataSetId))
  result = call_611501.call(path_611502, nil, nil, nil, nil)

var getRevision* = Call_GetRevision_611488(name: "getRevision",
                                        meth: HttpMethod.HttpGet,
                                        host: "dataexchange.amazonaws.com", route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
                                        validator: validate_GetRevision_611489,
                                        base: "/", url: url_GetRevision_611490,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRevision_611518 = ref object of OpenApiRestCall_610658
proc url_UpdateRevision_611520(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateRevision_611519(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation updates a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_611521 = path.getOrDefault("RevisionId")
  valid_611521 = validateParameter(valid_611521, JString, required = true,
                                 default = nil)
  if valid_611521 != nil:
    section.add "RevisionId", valid_611521
  var valid_611522 = path.getOrDefault("DataSetId")
  valid_611522 = validateParameter(valid_611522, JString, required = true,
                                 default = nil)
  if valid_611522 != nil:
    section.add "DataSetId", valid_611522
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611523 = header.getOrDefault("X-Amz-Signature")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Signature", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Content-Sha256", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Date")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Date", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Credential")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Credential", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Security-Token")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Security-Token", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Algorithm")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Algorithm", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-SignedHeaders", valid_611529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611531: Call_UpdateRevision_611518; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation updates a revision.
  ## 
  let valid = call_611531.validator(path, query, header, formData, body)
  let scheme = call_611531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611531.url(scheme.get, call_611531.host, call_611531.base,
                         call_611531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611531, url, valid)

proc call*(call_611532: Call_UpdateRevision_611518; RevisionId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateRevision
  ## This operation updates a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   body: JObject (required)
  var path_611533 = newJObject()
  var body_611534 = newJObject()
  add(path_611533, "RevisionId", newJString(RevisionId))
  add(path_611533, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_611534 = body
  result = call_611532.call(path_611533, nil, nil, nil, body_611534)

var updateRevision* = Call_UpdateRevision_611518(name: "updateRevision",
    meth: HttpMethod.HttpPatch, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_UpdateRevision_611519, base: "/", url: url_UpdateRevision_611520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRevision_611503 = ref object of OpenApiRestCall_610658
proc url_DeleteRevision_611505(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteRevision_611504(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## This operation deletes a revision.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_611506 = path.getOrDefault("RevisionId")
  valid_611506 = validateParameter(valid_611506, JString, required = true,
                                 default = nil)
  if valid_611506 != nil:
    section.add "RevisionId", valid_611506
  var valid_611507 = path.getOrDefault("DataSetId")
  valid_611507 = validateParameter(valid_611507, JString, required = true,
                                 default = nil)
  if valid_611507 != nil:
    section.add "DataSetId", valid_611507
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611508 = header.getOrDefault("X-Amz-Signature")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Signature", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Content-Sha256", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Date")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Date", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Credential")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Credential", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Security-Token")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Security-Token", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Algorithm")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Algorithm", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-SignedHeaders", valid_611514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611515: Call_DeleteRevision_611503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation deletes a revision.
  ## 
  let valid = call_611515.validator(path, query, header, formData, body)
  let scheme = call_611515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611515.url(scheme.get, call_611515.host, call_611515.base,
                         call_611515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611515, url, valid)

proc call*(call_611516: Call_DeleteRevision_611503; RevisionId: string;
          DataSetId: string): Recallable =
  ## deleteRevision
  ## This operation deletes a revision.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  var path_611517 = newJObject()
  add(path_611517, "RevisionId", newJString(RevisionId))
  add(path_611517, "DataSetId", newJString(DataSetId))
  result = call_611516.call(path_611517, nil, nil, nil, nil)

var deleteRevision* = Call_DeleteRevision_611503(name: "deleteRevision",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}",
    validator: validate_DeleteRevision_611504, base: "/", url: url_DeleteRevision_611505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRevisionAssets_611535 = ref object of OpenApiRestCall_610658
proc url_ListRevisionAssets_611537(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "RevisionId" in path, "`RevisionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/revisions/"),
               (kind: VariableSegment, value: "RevisionId"),
               (kind: ConstantSegment, value: "/assets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListRevisionAssets_611536(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RevisionId: JString (required)
  ##             : The unique identifier for a revision.
  ##   DataSetId: JString (required)
  ##            : The unique identifier for a data set.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `RevisionId` field"
  var valid_611538 = path.getOrDefault("RevisionId")
  valid_611538 = validateParameter(valid_611538, JString, required = true,
                                 default = nil)
  if valid_611538 != nil:
    section.add "RevisionId", valid_611538
  var valid_611539 = path.getOrDefault("DataSetId")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = nil)
  if valid_611539 != nil:
    section.add "DataSetId", valid_611539
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The maximum number of results returned by a single call.
  section = newJObject()
  var valid_611540 = query.getOrDefault("nextToken")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "nextToken", valid_611540
  var valid_611541 = query.getOrDefault("MaxResults")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "MaxResults", valid_611541
  var valid_611542 = query.getOrDefault("NextToken")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "NextToken", valid_611542
  var valid_611543 = query.getOrDefault("maxResults")
  valid_611543 = validateParameter(valid_611543, JInt, required = false, default = nil)
  if valid_611543 != nil:
    section.add "maxResults", valid_611543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611544 = header.getOrDefault("X-Amz-Signature")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Signature", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Content-Sha256", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Date")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Date", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-Credential")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-Credential", valid_611547
  var valid_611548 = header.getOrDefault("X-Amz-Security-Token")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Security-Token", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Algorithm")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Algorithm", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-SignedHeaders", valid_611550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611551: Call_ListRevisionAssets_611535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ## 
  let valid = call_611551.validator(path, query, header, formData, body)
  let scheme = call_611551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611551.url(scheme.get, call_611551.host, call_611551.base,
                         call_611551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611551, url, valid)

proc call*(call_611552: Call_ListRevisionAssets_611535; RevisionId: string;
          DataSetId: string; nextToken: string = ""; MaxResults: string = "";
          NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listRevisionAssets
  ## This operation lists a revision's assets sorted alphabetically in descending order.
  ##   RevisionId: string (required)
  ##             : The unique identifier for a revision.
  ##   nextToken: string
  ##            : The token value retrieved from a previous call to access the next page of results.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The unique identifier for a data set.
  ##   maxResults: int
  ##             : The maximum number of results returned by a single call.
  var path_611553 = newJObject()
  var query_611554 = newJObject()
  add(path_611553, "RevisionId", newJString(RevisionId))
  add(query_611554, "nextToken", newJString(nextToken))
  add(query_611554, "MaxResults", newJString(MaxResults))
  add(query_611554, "NextToken", newJString(NextToken))
  add(path_611553, "DataSetId", newJString(DataSetId))
  add(query_611554, "maxResults", newJInt(maxResults))
  result = call_611552.call(path_611553, query_611554, nil, nil, nil)

var listRevisionAssets* = Call_ListRevisionAssets_611535(
    name: "listRevisionAssets", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com",
    route: "/v1/data-sets/{DataSetId}/revisions/{RevisionId}/assets",
    validator: validate_ListRevisionAssets_611536, base: "/",
    url: url_ListRevisionAssets_611537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611569 = ref object of OpenApiRestCall_610658
proc url_TagResource_611571(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611570(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation tags a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_611572 = path.getOrDefault("resource-arn")
  valid_611572 = validateParameter(valid_611572, JString, required = true,
                                 default = nil)
  if valid_611572 != nil:
    section.add "resource-arn", valid_611572
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611573 = header.getOrDefault("X-Amz-Signature")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Signature", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Content-Sha256", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-Date")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Date", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Credential")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Credential", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Security-Token")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Security-Token", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Algorithm")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Algorithm", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-SignedHeaders", valid_611579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611581: Call_TagResource_611569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation tags a resource.
  ## 
  let valid = call_611581.validator(path, query, header, formData, body)
  let scheme = call_611581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611581.url(scheme.get, call_611581.host, call_611581.base,
                         call_611581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611581, url, valid)

proc call*(call_611582: Call_TagResource_611569; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## This operation tags a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   body: JObject (required)
  var path_611583 = newJObject()
  var body_611584 = newJObject()
  add(path_611583, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_611584 = body
  result = call_611582.call(path_611583, nil, nil, nil, body_611584)

var tagResource* = Call_TagResource_611569(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "dataexchange.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_611570,
                                        base: "/", url: url_TagResource_611571,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611555 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611557(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611556(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## This operation lists the tags on the resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_611558 = path.getOrDefault("resource-arn")
  valid_611558 = validateParameter(valid_611558, JString, required = true,
                                 default = nil)
  if valid_611558 != nil:
    section.add "resource-arn", valid_611558
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611559 = header.getOrDefault("X-Amz-Signature")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Signature", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Content-Sha256", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Date")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Date", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-Credential")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Credential", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Security-Token")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Security-Token", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Algorithm")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Algorithm", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-SignedHeaders", valid_611565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611566: Call_ListTagsForResource_611555; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation lists the tags on the resource.
  ## 
  let valid = call_611566.validator(path, query, header, formData, body)
  let scheme = call_611566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611566.url(scheme.get, call_611566.host, call_611566.base,
                         call_611566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611566, url, valid)

proc call*(call_611567: Call_ListTagsForResource_611555; resourceArn: string): Recallable =
  ## listTagsForResource
  ## This operation lists the tags on the resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  var path_611568 = newJObject()
  add(path_611568, "resource-arn", newJString(resourceArn))
  result = call_611567.call(path_611568, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611555(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "dataexchange.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_611556, base: "/",
    url: url_ListTagsForResource_611557, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611585 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611587(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611586(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## This operation removes one or more tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_611588 = path.getOrDefault("resource-arn")
  valid_611588 = validateParameter(valid_611588, JString, required = true,
                                 default = nil)
  if valid_611588 != nil:
    section.add "resource-arn", valid_611588
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611589 = query.getOrDefault("tagKeys")
  valid_611589 = validateParameter(valid_611589, JArray, required = true, default = nil)
  if valid_611589 != nil:
    section.add "tagKeys", valid_611589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611590 = header.getOrDefault("X-Amz-Signature")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Signature", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Content-Sha256", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Date")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Date", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Credential")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Credential", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Security-Token")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Security-Token", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Algorithm")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Algorithm", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-SignedHeaders", valid_611596
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611597: Call_UntagResource_611585; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This operation removes one or more tags from a resource.
  ## 
  let valid = call_611597.validator(path, query, header, formData, body)
  let scheme = call_611597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611597.url(scheme.get, call_611597.host, call_611597.base,
                         call_611597.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611597, url, valid)

proc call*(call_611598: Call_UntagResource_611585; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## This operation removes one or more tags from a resource.
  ##   resourceArn: string (required)
  ##              : An Amazon Resource Name (ARN) that uniquely identifies an AWS resource.
  ##   tagKeys: JArray (required)
  ##          : The key tags.
  var path_611599 = newJObject()
  var query_611600 = newJObject()
  add(path_611599, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_611600.add "tagKeys", tagKeys
  result = call_611598.call(path_611599, query_611600, nil, nil, nil)

var untagResource* = Call_UntagResource_611585(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "dataexchange.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_611586,
    base: "/", url: url_UntagResource_611587, schemes: {Scheme.Https, Scheme.Http})
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
