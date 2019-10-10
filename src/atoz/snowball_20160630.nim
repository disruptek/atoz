
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Import/Export Snowball
## version: 2016-06-30
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Snowball is a petabyte-scale data transport solution that uses secure devices to transfer large amounts of data between your on-premises data centers and Amazon Simple Storage Service (Amazon S3). The commands described here provide access to the same functionality that is available in the AWS Snowball Management Console, which enables you to create and manage jobs for Snowball and Snowball Edge devices. To transfer data locally with a device, you'll need to use the Snowball client or the Amazon S3 API adapter for Snowball.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/snowball/
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "snowball.ap-northeast-1.amazonaws.com", "ap-southeast-1": "snowball.ap-southeast-1.amazonaws.com",
                           "us-west-2": "snowball.us-west-2.amazonaws.com",
                           "eu-west-2": "snowball.eu-west-2.amazonaws.com", "ap-northeast-3": "snowball.ap-northeast-3.amazonaws.com", "eu-central-1": "snowball.eu-central-1.amazonaws.com",
                           "us-east-2": "snowball.us-east-2.amazonaws.com",
                           "us-east-1": "snowball.us-east-1.amazonaws.com", "cn-northwest-1": "snowball.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "snowball.ap-south-1.amazonaws.com",
                           "eu-north-1": "snowball.eu-north-1.amazonaws.com", "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
                           "us-west-1": "snowball.us-west-1.amazonaws.com", "us-gov-east-1": "snowball.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "snowball.eu-west-3.amazonaws.com", "cn-north-1": "snowball.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "snowball.sa-east-1.amazonaws.com",
                           "eu-west-1": "snowball.eu-west-1.amazonaws.com", "us-gov-west-1": "snowball.us-gov-west-1.amazonaws.com", "ap-southeast-2": "snowball.ap-southeast-2.amazonaws.com", "ca-central-1": "snowball.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "snowball.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "snowball.ap-southeast-1.amazonaws.com",
      "us-west-2": "snowball.us-west-2.amazonaws.com",
      "eu-west-2": "snowball.eu-west-2.amazonaws.com",
      "ap-northeast-3": "snowball.ap-northeast-3.amazonaws.com",
      "eu-central-1": "snowball.eu-central-1.amazonaws.com",
      "us-east-2": "snowball.us-east-2.amazonaws.com",
      "us-east-1": "snowball.us-east-1.amazonaws.com",
      "cn-northwest-1": "snowball.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "snowball.ap-south-1.amazonaws.com",
      "eu-north-1": "snowball.eu-north-1.amazonaws.com",
      "ap-northeast-2": "snowball.ap-northeast-2.amazonaws.com",
      "us-west-1": "snowball.us-west-1.amazonaws.com",
      "us-gov-east-1": "snowball.us-gov-east-1.amazonaws.com",
      "eu-west-3": "snowball.eu-west-3.amazonaws.com",
      "cn-north-1": "snowball.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "snowball.sa-east-1.amazonaws.com",
      "eu-west-1": "snowball.eu-west-1.amazonaws.com",
      "us-gov-west-1": "snowball.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "snowball.ap-southeast-2.amazonaws.com",
      "ca-central-1": "snowball.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "snowball"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CancelCluster_602803 = ref object of OpenApiRestCall_602466
proc url_CancelCluster_602805(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelCluster_602804(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelCluster"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_CancelCluster_602803; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_CancelCluster_602803; body: JsonNode): Recallable =
  ## cancelCluster
  ## Cancels a cluster job. You can only cancel a cluster job while it's in the <code>AwaitingQuorum</code> status. You'll have at least an hour after creating a cluster job to cancel it.
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var cancelCluster* = Call_CancelCluster_602803(name: "cancelCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelCluster",
    validator: validate_CancelCluster_602804, base: "/", url: url_CancelCluster_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelJob_603072 = ref object of OpenApiRestCall_602466
proc url_CancelJob_603074(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelJob_603073(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CancelJob"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_CancelJob_603072; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_CancelJob_603072; body: JsonNode): Recallable =
  ## cancelJob
  ## Cancels the specified job. You can only cancel a job before its <code>JobState</code> value changes to <code>PreparingAppliance</code>. Requesting the <code>ListJobs</code> or <code>DescribeJob</code> action returns a job's <code>JobState</code> as part of the response element data returned.
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var cancelJob* = Call_CancelJob_603072(name: "cancelJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CancelJob",
                                    validator: validate_CancelJob_603073,
                                    base: "/", url: url_CancelJob_603074,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAddress_603087 = ref object of OpenApiRestCall_602466
proc url_CreateAddress_603089(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateAddress_603088(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateAddress"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_CreateAddress_603087; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_CreateAddress_603087; body: JsonNode): Recallable =
  ## createAddress
  ## Creates an address for a Snowball to be shipped to. In most regions, addresses are validated at the time of creation. The address you provide must be located within the serviceable area of your region. If the address is invalid or unsupported, then an exception is thrown.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var createAddress* = Call_CreateAddress_603087(name: "createAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateAddress",
    validator: validate_CreateAddress_603088, base: "/", url: url_CreateAddress_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateCluster_603102 = ref object of OpenApiRestCall_602466
proc url_CreateCluster_603104(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateCluster_603103(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateCluster"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_CreateCluster_603102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_CreateCluster_603102; body: JsonNode): Recallable =
  ## createCluster
  ## Creates an empty cluster. Each cluster supports five nodes. You use the <a>CreateJob</a> action separately to create the jobs for each of these nodes. The cluster does not ship until these five node jobs have been created.
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var createCluster* = Call_CreateCluster_603102(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateCluster",
    validator: validate_CreateCluster_603103, base: "/", url: url_CreateCluster_603104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateJob_603117 = ref object of OpenApiRestCall_602466
proc url_CreateJob_603119(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateJob_603118(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.CreateJob"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_CreateJob_603117; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_CreateJob_603117; body: JsonNode): Recallable =
  ## createJob
  ## Creates a job to import or export data between Amazon S3 and your on-premises data center. Your AWS account must have the right trust policies and permissions in place to create a job for Snowball. If you're creating a job for a node in a cluster, you only need to provide the <code>clusterId</code> value; the other job attributes are inherited from the cluster. 
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var createJob* = Call_CreateJob_603117(name: "createJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.CreateJob",
                                    validator: validate_CreateJob_603118,
                                    base: "/", url: url_CreateJob_603119,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddress_603132 = ref object of OpenApiRestCall_602466
proc url_DescribeAddress_603134(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAddress_603133(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddress"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_DescribeAddress_603132; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_DescribeAddress_603132; body: JsonNode): Recallable =
  ## describeAddress
  ## Takes an <code>AddressId</code> and returns specific details about that address in the form of an <code>Address</code> object.
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var describeAddress* = Call_DescribeAddress_603132(name: "describeAddress",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddress",
    validator: validate_DescribeAddress_603133, base: "/", url: url_DescribeAddress_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAddresses_603147 = ref object of OpenApiRestCall_602466
proc url_DescribeAddresses_603149(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAddresses_603148(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603150 = query.getOrDefault("NextToken")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "NextToken", valid_603150
  var valid_603151 = query.getOrDefault("MaxResults")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "MaxResults", valid_603151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603152 = header.getOrDefault("X-Amz-Date")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Date", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Security-Token")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Security-Token", valid_603153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603154 = header.getOrDefault("X-Amz-Target")
  valid_603154 = validateParameter(valid_603154, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeAddresses"))
  if valid_603154 != nil:
    section.add "X-Amz-Target", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Content-Sha256", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Algorithm")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Algorithm", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Signature")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Signature", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-SignedHeaders", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-Credential")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Credential", valid_603159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603161: Call_DescribeAddresses_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ## 
  let valid = call_603161.validator(path, query, header, formData, body)
  let scheme = call_603161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603161.url(scheme.get, call_603161.host, call_603161.base,
                         call_603161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603161, url, valid)

proc call*(call_603162: Call_DescribeAddresses_603147; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeAddresses
  ## Returns a specified number of <code>ADDRESS</code> objects. Calling this API in one of the US regions will return addresses from the list of all addresses associated with this account in all US regions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603163 = newJObject()
  var body_603164 = newJObject()
  add(query_603163, "NextToken", newJString(NextToken))
  if body != nil:
    body_603164 = body
  add(query_603163, "MaxResults", newJString(MaxResults))
  result = call_603162.call(nil, query_603163, nil, nil, body_603164)

var describeAddresses* = Call_DescribeAddresses_603147(name: "describeAddresses",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeAddresses",
    validator: validate_DescribeAddresses_603148, base: "/",
    url: url_DescribeAddresses_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_603166 = ref object of OpenApiRestCall_602466
proc url_DescribeCluster_603168(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeCluster_603167(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603169 = header.getOrDefault("X-Amz-Date")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Date", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Security-Token")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Security-Token", valid_603170
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603171 = header.getOrDefault("X-Amz-Target")
  valid_603171 = validateParameter(valid_603171, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeCluster"))
  if valid_603171 != nil:
    section.add "X-Amz-Target", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Content-Sha256", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Signature")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Signature", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-SignedHeaders", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Credential")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Credential", valid_603176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603178: Call_DescribeCluster_603166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ## 
  let valid = call_603178.validator(path, query, header, formData, body)
  let scheme = call_603178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603178.url(scheme.get, call_603178.host, call_603178.base,
                         call_603178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603178, url, valid)

proc call*(call_603179: Call_DescribeCluster_603166; body: JsonNode): Recallable =
  ## describeCluster
  ## Returns information about a specific cluster including shipping information, cluster status, and other important metadata.
  ##   body: JObject (required)
  var body_603180 = newJObject()
  if body != nil:
    body_603180 = body
  result = call_603179.call(nil, nil, nil, nil, body_603180)

var describeCluster* = Call_DescribeCluster_603166(name: "describeCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeCluster",
    validator: validate_DescribeCluster_603167, base: "/", url: url_DescribeCluster_603168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJob_603181 = ref object of OpenApiRestCall_602466
proc url_DescribeJob_603183(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeJob_603182(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603184 = header.getOrDefault("X-Amz-Date")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Date", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Security-Token")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Security-Token", valid_603185
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603186 = header.getOrDefault("X-Amz-Target")
  valid_603186 = validateParameter(valid_603186, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.DescribeJob"))
  if valid_603186 != nil:
    section.add "X-Amz-Target", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Content-Sha256", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Signature")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Signature", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-SignedHeaders", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Credential")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Credential", valid_603191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603193: Call_DescribeJob_603181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ## 
  let valid = call_603193.validator(path, query, header, formData, body)
  let scheme = call_603193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603193.url(scheme.get, call_603193.host, call_603193.base,
                         call_603193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603193, url, valid)

proc call*(call_603194: Call_DescribeJob_603181; body: JsonNode): Recallable =
  ## describeJob
  ## Returns information about a specific job including shipping information, job status, and other important metadata. 
  ##   body: JObject (required)
  var body_603195 = newJObject()
  if body != nil:
    body_603195 = body
  result = call_603194.call(nil, nil, nil, nil, body_603195)

var describeJob* = Call_DescribeJob_603181(name: "describeJob",
                                        meth: HttpMethod.HttpPost,
                                        host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.DescribeJob",
                                        validator: validate_DescribeJob_603182,
                                        base: "/", url: url_DescribeJob_603183,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobManifest_603196 = ref object of OpenApiRestCall_602466
proc url_GetJobManifest_603198(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobManifest_603197(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603199 = header.getOrDefault("X-Amz-Date")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Date", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Security-Token")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Security-Token", valid_603200
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603201 = header.getOrDefault("X-Amz-Target")
  valid_603201 = validateParameter(valid_603201, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobManifest"))
  if valid_603201 != nil:
    section.add "X-Amz-Target", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Content-Sha256", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Algorithm")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Algorithm", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Signature")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Signature", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-SignedHeaders", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Credential")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Credential", valid_603206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603208: Call_GetJobManifest_603196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ## 
  let valid = call_603208.validator(path, query, header, formData, body)
  let scheme = call_603208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603208.url(scheme.get, call_603208.host, call_603208.base,
                         call_603208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603208, url, valid)

proc call*(call_603209: Call_GetJobManifest_603196; body: JsonNode): Recallable =
  ## getJobManifest
  ## <p>Returns a link to an Amazon S3 presigned URL for the manifest file associated with the specified <code>JobId</code> value. You can access the manifest file for up to 60 minutes after this request has been made. To access the manifest file after 60 minutes have passed, you'll have to make another call to the <code>GetJobManifest</code> action.</p> <p>The manifest is an encrypted file that you can download after your job enters the <code>WithCustomer</code> status. The manifest is decrypted by using the <code>UnlockCode</code> code value, when you pass both values to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of an <code>UnlockCode</code> value in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p> <p>The credentials of a given job, including its manifest file and unlock code, expire 90 days after the job is created.</p>
  ##   body: JObject (required)
  var body_603210 = newJObject()
  if body != nil:
    body_603210 = body
  result = call_603209.call(nil, nil, nil, nil, body_603210)

var getJobManifest* = Call_GetJobManifest_603196(name: "getJobManifest",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobManifest",
    validator: validate_GetJobManifest_603197, base: "/", url: url_GetJobManifest_603198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetJobUnlockCode_603211 = ref object of OpenApiRestCall_602466
proc url_GetJobUnlockCode_603213(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetJobUnlockCode_603212(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603214 = header.getOrDefault("X-Amz-Date")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Date", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Security-Token")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Security-Token", valid_603215
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603216 = header.getOrDefault("X-Amz-Target")
  valid_603216 = validateParameter(valid_603216, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetJobUnlockCode"))
  if valid_603216 != nil:
    section.add "X-Amz-Target", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Content-Sha256", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Algorithm")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Algorithm", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Signature")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Signature", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-SignedHeaders", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Credential")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Credential", valid_603221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603223: Call_GetJobUnlockCode_603211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ## 
  let valid = call_603223.validator(path, query, header, formData, body)
  let scheme = call_603223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603223.url(scheme.get, call_603223.host, call_603223.base,
                         call_603223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603223, url, valid)

proc call*(call_603224: Call_GetJobUnlockCode_603211; body: JsonNode): Recallable =
  ## getJobUnlockCode
  ## <p>Returns the <code>UnlockCode</code> code value for the specified job. A particular <code>UnlockCode</code> value can be accessed for up to 90 days after the associated job has been created.</p> <p>The <code>UnlockCode</code> value is a 29-character code with 25 alphanumeric characters and 4 hyphens. This code is used to decrypt the manifest file when it is passed along with the manifest to the Snowball through the Snowball client when the client is started for the first time.</p> <p>As a best practice, we recommend that you don't save a copy of the <code>UnlockCode</code> in the same location as the manifest file for that job. Saving these separately helps prevent unauthorized parties from gaining access to the Snowball associated with that job.</p>
  ##   body: JObject (required)
  var body_603225 = newJObject()
  if body != nil:
    body_603225 = body
  result = call_603224.call(nil, nil, nil, nil, body_603225)

var getJobUnlockCode* = Call_GetJobUnlockCode_603211(name: "getJobUnlockCode",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetJobUnlockCode",
    validator: validate_GetJobUnlockCode_603212, base: "/",
    url: url_GetJobUnlockCode_603213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSnowballUsage_603226 = ref object of OpenApiRestCall_602466
proc url_GetSnowballUsage_603228(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSnowballUsage_603227(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603229 = header.getOrDefault("X-Amz-Date")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Date", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Security-Token")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Security-Token", valid_603230
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603231 = header.getOrDefault("X-Amz-Target")
  valid_603231 = validateParameter(valid_603231, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.GetSnowballUsage"))
  if valid_603231 != nil:
    section.add "X-Amz-Target", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Content-Sha256", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Algorithm")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Algorithm", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Signature")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Signature", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-SignedHeaders", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Credential")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Credential", valid_603236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603238: Call_GetSnowballUsage_603226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ## 
  let valid = call_603238.validator(path, query, header, formData, body)
  let scheme = call_603238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603238.url(scheme.get, call_603238.host, call_603238.base,
                         call_603238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603238, url, valid)

proc call*(call_603239: Call_GetSnowballUsage_603226; body: JsonNode): Recallable =
  ## getSnowballUsage
  ## <p>Returns information about the Snowball service limit for your account, and also the number of Snowballs your account has in use.</p> <p>The default service limit for the number of Snowballs that you can have at one time is 1. If you want to increase your service limit, contact AWS Support.</p>
  ##   body: JObject (required)
  var body_603240 = newJObject()
  if body != nil:
    body_603240 = body
  result = call_603239.call(nil, nil, nil, nil, body_603240)

var getSnowballUsage* = Call_GetSnowballUsage_603226(name: "getSnowballUsage",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.GetSnowballUsage",
    validator: validate_GetSnowballUsage_603227, base: "/",
    url: url_GetSnowballUsage_603228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusterJobs_603241 = ref object of OpenApiRestCall_602466
proc url_ListClusterJobs_603243(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListClusterJobs_603242(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603244 = header.getOrDefault("X-Amz-Date")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Date", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Security-Token")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Security-Token", valid_603245
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603246 = header.getOrDefault("X-Amz-Target")
  valid_603246 = validateParameter(valid_603246, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusterJobs"))
  if valid_603246 != nil:
    section.add "X-Amz-Target", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Content-Sha256", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Algorithm")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Algorithm", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Signature")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Signature", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-SignedHeaders", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Credential")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Credential", valid_603251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603253: Call_ListClusterJobs_603241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ## 
  let valid = call_603253.validator(path, query, header, formData, body)
  let scheme = call_603253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603253.url(scheme.get, call_603253.host, call_603253.base,
                         call_603253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603253, url, valid)

proc call*(call_603254: Call_ListClusterJobs_603241; body: JsonNode): Recallable =
  ## listClusterJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object is for a job in the specified cluster and contains a job's state, a job's ID, and other information.
  ##   body: JObject (required)
  var body_603255 = newJObject()
  if body != nil:
    body_603255 = body
  result = call_603254.call(nil, nil, nil, nil, body_603255)

var listClusterJobs* = Call_ListClusterJobs_603241(name: "listClusterJobs",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusterJobs",
    validator: validate_ListClusterJobs_603242, base: "/", url: url_ListClusterJobs_603243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_603256 = ref object of OpenApiRestCall_602466
proc url_ListClusters_603258(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListClusters_603257(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603259 = header.getOrDefault("X-Amz-Date")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Date", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Security-Token")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Security-Token", valid_603260
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603261 = header.getOrDefault("X-Amz-Target")
  valid_603261 = validateParameter(valid_603261, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListClusters"))
  if valid_603261 != nil:
    section.add "X-Amz-Target", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Content-Sha256", valid_603262
  var valid_603263 = header.getOrDefault("X-Amz-Algorithm")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Algorithm", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Signature")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Signature", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-SignedHeaders", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Credential")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Credential", valid_603266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603268: Call_ListClusters_603256; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ## 
  let valid = call_603268.validator(path, query, header, formData, body)
  let scheme = call_603268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603268.url(scheme.get, call_603268.host, call_603268.base,
                         call_603268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603268, url, valid)

proc call*(call_603269: Call_ListClusters_603256; body: JsonNode): Recallable =
  ## listClusters
  ## Returns an array of <code>ClusterListEntry</code> objects of the specified length. Each <code>ClusterListEntry</code> object contains a cluster's state, a cluster's ID, and other important status information.
  ##   body: JObject (required)
  var body_603270 = newJObject()
  if body != nil:
    body_603270 = body
  result = call_603269.call(nil, nil, nil, nil, body_603270)

var listClusters* = Call_ListClusters_603256(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListClusters",
    validator: validate_ListClusters_603257, base: "/", url: url_ListClusters_603258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCompatibleImages_603271 = ref object of OpenApiRestCall_602466
proc url_ListCompatibleImages_603273(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListCompatibleImages_603272(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on <code>EDGE</code>, <code>EDGE_C</code>, and <code>EDGE_CG</code> devices. For more information on compatible AMIs, see <a href="http://docs.aws.amazon.com/snowball/latest/developer-guide/using-ec2.html">Using Amazon EC2 Compute Instances</a> in the <i>AWS Snowball Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603274 = header.getOrDefault("X-Amz-Date")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Date", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Security-Token")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Security-Token", valid_603275
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603276 = header.getOrDefault("X-Amz-Target")
  valid_603276 = validateParameter(valid_603276, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListCompatibleImages"))
  if valid_603276 != nil:
    section.add "X-Amz-Target", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Content-Sha256", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Algorithm")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Algorithm", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Signature")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Signature", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-SignedHeaders", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Credential")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Credential", valid_603281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603283: Call_ListCompatibleImages_603271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on <code>EDGE</code>, <code>EDGE_C</code>, and <code>EDGE_CG</code> devices. For more information on compatible AMIs, see <a href="http://docs.aws.amazon.com/snowball/latest/developer-guide/using-ec2.html">Using Amazon EC2 Compute Instances</a> in the <i>AWS Snowball Developer Guide</i>.
  ## 
  let valid = call_603283.validator(path, query, header, formData, body)
  let scheme = call_603283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603283.url(scheme.get, call_603283.host, call_603283.base,
                         call_603283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603283, url, valid)

proc call*(call_603284: Call_ListCompatibleImages_603271; body: JsonNode): Recallable =
  ## listCompatibleImages
  ## This action returns a list of the different Amazon EC2 Amazon Machine Images (AMIs) that are owned by your AWS account that would be supported for use on <code>EDGE</code>, <code>EDGE_C</code>, and <code>EDGE_CG</code> devices. For more information on compatible AMIs, see <a href="http://docs.aws.amazon.com/snowball/latest/developer-guide/using-ec2.html">Using Amazon EC2 Compute Instances</a> in the <i>AWS Snowball Developer Guide</i>.
  ##   body: JObject (required)
  var body_603285 = newJObject()
  if body != nil:
    body_603285 = body
  result = call_603284.call(nil, nil, nil, nil, body_603285)

var listCompatibleImages* = Call_ListCompatibleImages_603271(
    name: "listCompatibleImages", meth: HttpMethod.HttpPost,
    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListCompatibleImages",
    validator: validate_ListCompatibleImages_603272, base: "/",
    url: url_ListCompatibleImages_603273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListJobs_603286 = ref object of OpenApiRestCall_602466
proc url_ListJobs_603288(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListJobs_603287(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_603289 = query.getOrDefault("NextToken")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "NextToken", valid_603289
  var valid_603290 = query.getOrDefault("MaxResults")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "MaxResults", valid_603290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603291 = header.getOrDefault("X-Amz-Date")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Date", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Security-Token")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Security-Token", valid_603292
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603293 = header.getOrDefault("X-Amz-Target")
  valid_603293 = validateParameter(valid_603293, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.ListJobs"))
  if valid_603293 != nil:
    section.add "X-Amz-Target", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Content-Sha256", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Algorithm")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Algorithm", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Signature")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Signature", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-SignedHeaders", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Credential")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Credential", valid_603298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603300: Call_ListJobs_603286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ## 
  let valid = call_603300.validator(path, query, header, formData, body)
  let scheme = call_603300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603300.url(scheme.get, call_603300.host, call_603300.base,
                         call_603300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603300, url, valid)

proc call*(call_603301: Call_ListJobs_603286; body: JsonNode; NextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listJobs
  ## Returns an array of <code>JobListEntry</code> objects of the specified length. Each <code>JobListEntry</code> object contains a job's state, a job's ID, and a value that indicates whether the job is a job part, in the case of export jobs. Calling this API action in one of the US regions will return jobs from the list of all jobs associated with this account in all US regions.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_603302 = newJObject()
  var body_603303 = newJObject()
  add(query_603302, "NextToken", newJString(NextToken))
  if body != nil:
    body_603303 = body
  add(query_603302, "MaxResults", newJString(MaxResults))
  result = call_603301.call(nil, query_603302, nil, nil, body_603303)

var listJobs* = Call_ListJobs_603286(name: "listJobs", meth: HttpMethod.HttpPost,
                                  host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.ListJobs",
                                  validator: validate_ListJobs_603287, base: "/",
                                  url: url_ListJobs_603288,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCluster_603304 = ref object of OpenApiRestCall_602466
proc url_UpdateCluster_603306(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateCluster_603305(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603307 = header.getOrDefault("X-Amz-Date")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Date", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Security-Token")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Security-Token", valid_603308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603309 = header.getOrDefault("X-Amz-Target")
  valid_603309 = validateParameter(valid_603309, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateCluster"))
  if valid_603309 != nil:
    section.add "X-Amz-Target", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Content-Sha256", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Algorithm")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Algorithm", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Signature")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Signature", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-SignedHeaders", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Credential")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Credential", valid_603314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603316: Call_UpdateCluster_603304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ## 
  let valid = call_603316.validator(path, query, header, formData, body)
  let scheme = call_603316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603316.url(scheme.get, call_603316.host, call_603316.base,
                         call_603316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603316, url, valid)

proc call*(call_603317: Call_UpdateCluster_603304; body: JsonNode): Recallable =
  ## updateCluster
  ## While a cluster's <code>ClusterState</code> value is in the <code>AwaitingQuorum</code> state, you can update some of the information associated with a cluster. Once the cluster changes to a different job state, usually 60 minutes after the cluster being created, this action is no longer available.
  ##   body: JObject (required)
  var body_603318 = newJObject()
  if body != nil:
    body_603318 = body
  result = call_603317.call(nil, nil, nil, nil, body_603318)

var updateCluster* = Call_UpdateCluster_603304(name: "updateCluster",
    meth: HttpMethod.HttpPost, host: "snowball.amazonaws.com",
    route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateCluster",
    validator: validate_UpdateCluster_603305, base: "/", url: url_UpdateCluster_603306,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateJob_603319 = ref object of OpenApiRestCall_602466
proc url_UpdateJob_603321(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateJob_603320(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603322 = header.getOrDefault("X-Amz-Date")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Date", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Security-Token")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Security-Token", valid_603323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603324 = header.getOrDefault("X-Amz-Target")
  valid_603324 = validateParameter(valid_603324, JString, required = true, default = newJString(
      "AWSIESnowballJobManagementService.UpdateJob"))
  if valid_603324 != nil:
    section.add "X-Amz-Target", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Content-Sha256", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Algorithm")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Algorithm", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Signature")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Signature", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-SignedHeaders", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Credential")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Credential", valid_603329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603331: Call_UpdateJob_603319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ## 
  let valid = call_603331.validator(path, query, header, formData, body)
  let scheme = call_603331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603331.url(scheme.get, call_603331.host, call_603331.base,
                         call_603331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603331, url, valid)

proc call*(call_603332: Call_UpdateJob_603319; body: JsonNode): Recallable =
  ## updateJob
  ## While a job's <code>JobState</code> value is <code>New</code>, you can update some of the information associated with a job. Once the job changes to a different job state, usually within 60 minutes of the job being created, this action is no longer available.
  ##   body: JObject (required)
  var body_603333 = newJObject()
  if body != nil:
    body_603333 = body
  result = call_603332.call(nil, nil, nil, nil, body_603333)

var updateJob* = Call_UpdateJob_603319(name: "updateJob", meth: HttpMethod.HttpPost,
                                    host: "snowball.amazonaws.com", route: "/#X-Amz-Target=AWSIESnowballJobManagementService.UpdateJob",
                                    validator: validate_UpdateJob_603320,
                                    base: "/", url: url_UpdateJob_603321,
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
