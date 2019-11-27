
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CloudTrail
## version: 2013-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CloudTrail</fullname> <p>This is the CloudTrail API Reference. It provides descriptions of actions, data types, common parameters, and common errors for CloudTrail.</p> <p>CloudTrail is a web service that records AWS API calls for your AWS account and delivers log files to an Amazon S3 bucket. The recorded information includes the identity of the user, the start time of the AWS API call, the source IP address, the request parameters, and the response elements returned by the service.</p> <note> <p>As an alternative to the API, you can use one of the AWS SDKs, which consist of libraries and sample code for various programming languages and platforms (Java, Ruby, .NET, iOS, Android, etc.). The SDKs provide a convenient way to create programmatic access to AWSCloudTrail. For example, the SDKs take care of cryptographically signing requests, managing errors, and retrying requests automatically. For information about the AWS SDKs, including how to download and install them, see the <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services page</a>.</p> </note> <p>See the <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html">AWS CloudTrail User Guide</a> for information about the data that is included with each AWS API call listed in the log files.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudtrail/
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudtrail.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudtrail.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudtrail.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudtrail.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudtrail.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudtrail.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudtrail.us-east-2.amazonaws.com",
                           "us-east-1": "cloudtrail.us-east-1.amazonaws.com", "cn-northwest-1": "cloudtrail.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "cloudtrail.ap-south-1.amazonaws.com",
                           "eu-north-1": "cloudtrail.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudtrail.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudtrail.us-west-1.amazonaws.com", "us-gov-east-1": "cloudtrail.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudtrail.eu-west-3.amazonaws.com", "cn-north-1": "cloudtrail.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudtrail.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudtrail.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudtrail.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudtrail.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudtrail.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudtrail.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudtrail.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudtrail.us-west-2.amazonaws.com",
      "eu-west-2": "cloudtrail.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudtrail.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudtrail.eu-central-1.amazonaws.com",
      "us-east-2": "cloudtrail.us-east-2.amazonaws.com",
      "us-east-1": "cloudtrail.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudtrail.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudtrail.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudtrail.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudtrail.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudtrail.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudtrail.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudtrail.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudtrail.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudtrail.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudtrail.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudtrail.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudtrail.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudtrail.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudtrail"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_599705 = ref object of OpenApiRestCall_599368
proc url_AddTags_599707(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds one or more tags to a trail, up to a limit of 50. Overwrites an existing tag's value when a new value is specified for an existing tag key. Tag key names must be unique for a trail; you cannot have two keys with the same name but different values. If you specify a key without a value, the tag will be created with the specified key and a value of null. You can tag a trail that applies to all AWS Regions only from the Region in which the trail was created (also known as its home region).
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
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.AddTags"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_AddTags_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more tags to a trail, up to a limit of 50. Overwrites an existing tag's value when a new value is specified for an existing tag key. Tag key names must be unique for a trail; you cannot have two keys with the same name but different values. If you specify a key without a value, the tag will be created with the specified key and a value of null. You can tag a trail that applies to all AWS Regions only from the Region in which the trail was created (also known as its home region).
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AddTags_599705; body: JsonNode): Recallable =
  ## addTags
  ## Adds one or more tags to a trail, up to a limit of 50. Overwrites an existing tag's value when a new value is specified for an existing tag key. Tag key names must be unique for a trail; you cannot have two keys with the same name but different values. If you specify a key without a value, the tag will be created with the specified key and a value of null. You can tag a trail that applies to all AWS Regions only from the Region in which the trail was created (also known as its home region).
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var addTags* = Call_AddTags_599705(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.AddTags",
                                validator: validate_AddTags_599706, base: "/",
                                url: url_AddTags_599707,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTrail_599974 = ref object of OpenApiRestCall_599368
proc url_CreateTrail_599976(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateTrail_599975(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a trail that specifies the settings for delivery of log data to an Amazon S3 bucket. 
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
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateTrail"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CreateTrail_599974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a trail that specifies the settings for delivery of log data to an Amazon S3 bucket. 
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CreateTrail_599974; body: JsonNode): Recallable =
  ## createTrail
  ## Creates a trail that specifies the settings for delivery of log data to an Amazon S3 bucket. 
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var createTrail* = Call_CreateTrail_599974(name: "createTrail",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.CreateTrail",
                                        validator: validate_CreateTrail_599975,
                                        base: "/", url: url_CreateTrail_599976,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTrail_599989 = ref object of OpenApiRestCall_599368
proc url_DeleteTrail_599991(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteTrail_599990(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a trail. This operation must be called from the region in which the trail was created. <code>DeleteTrail</code> cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
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
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteTrail"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_DeleteTrail_599989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a trail. This operation must be called from the region in which the trail was created. <code>DeleteTrail</code> cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_DeleteTrail_599989; body: JsonNode): Recallable =
  ## deleteTrail
  ## Deletes a trail. This operation must be called from the region in which the trail was created. <code>DeleteTrail</code> cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var deleteTrail* = Call_DeleteTrail_599989(name: "deleteTrail",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DeleteTrail",
                                        validator: validate_DeleteTrail_599990,
                                        base: "/", url: url_DeleteTrail_599991,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTrails_600004 = ref object of OpenApiRestCall_599368
proc url_DescribeTrails_600006(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeTrails_600005(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves settings for one or more trails associated with the current region for your account.
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
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeTrails"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_DescribeTrails_600004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves settings for one or more trails associated with the current region for your account.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_DescribeTrails_600004; body: JsonNode): Recallable =
  ## describeTrails
  ## Retrieves settings for one or more trails associated with the current region for your account.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var describeTrails* = Call_DescribeTrails_600004(name: "describeTrails",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.DescribeTrails",
    validator: validate_DescribeTrails_600005, base: "/", url: url_DescribeTrails_600006,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSelectors_600019 = ref object of OpenApiRestCall_599368
proc url_GetEventSelectors_600021(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEventSelectors_600020(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Describes the settings for the event selectors that you configured for your trail. The information returned for your event selectors includes the following:</p> <ul> <li> <p>If your event selector includes read-only events, write-only events, or all events. This applies to both management events and data events.</p> </li> <li> <p>If your event selector includes management events.</p> </li> <li> <p>If your event selector includes data events, the Amazon S3 objects or AWS Lambda functions that you are logging for data events.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
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
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString("com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventSelectors"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_GetEventSelectors_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the settings for the event selectors that you configured for your trail. The information returned for your event selectors includes the following:</p> <ul> <li> <p>If your event selector includes read-only events, write-only events, or all events. This applies to both management events and data events.</p> </li> <li> <p>If your event selector includes management events.</p> </li> <li> <p>If your event selector includes data events, the Amazon S3 objects or AWS Lambda functions that you are logging for data events.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_GetEventSelectors_600019; body: JsonNode): Recallable =
  ## getEventSelectors
  ## <p>Describes the settings for the event selectors that you configured for your trail. The information returned for your event selectors includes the following:</p> <ul> <li> <p>If your event selector includes read-only events, write-only events, or all events. This applies to both management events and data events.</p> </li> <li> <p>If your event selector includes management events.</p> </li> <li> <p>If your event selector includes data events, the Amazon S3 objects or AWS Lambda functions that you are logging for data events.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var getEventSelectors* = Call_GetEventSelectors_600019(name: "getEventSelectors",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetEventSelectors",
    validator: validate_GetEventSelectors_600020, base: "/",
    url: url_GetEventSelectors_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInsightSelectors_600034 = ref object of OpenApiRestCall_599368
proc url_GetInsightSelectors_600036(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInsightSelectors_600035(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Describes the settings for the Insights event selectors that you configured for your trail. <code>GetInsightSelectors</code> shows if CloudTrail Insights event logging is enabled on the trail, and if it is, which insight types are enabled. If you run <code>GetInsightSelectors</code> on a trail that does not have Insights events enabled, the operation throws the exception <code>InsightNotEnabledException</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-insights-events-with-cloudtrail.html">Logging CloudTrail Insights Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
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
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString("com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetInsightSelectors"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_GetInsightSelectors_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the settings for the Insights event selectors that you configured for your trail. <code>GetInsightSelectors</code> shows if CloudTrail Insights event logging is enabled on the trail, and if it is, which insight types are enabled. If you run <code>GetInsightSelectors</code> on a trail that does not have Insights events enabled, the operation throws the exception <code>InsightNotEnabledException</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-insights-events-with-cloudtrail.html">Logging CloudTrail Insights Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_GetInsightSelectors_600034; body: JsonNode): Recallable =
  ## getInsightSelectors
  ## <p>Describes the settings for the Insights event selectors that you configured for your trail. <code>GetInsightSelectors</code> shows if CloudTrail Insights event logging is enabled on the trail, and if it is, which insight types are enabled. If you run <code>GetInsightSelectors</code> on a trail that does not have Insights events enabled, the operation throws the exception <code>InsightNotEnabledException</code> </p> <p>For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-insights-events-with-cloudtrail.html">Logging CloudTrail Insights Events for Trails </a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var getInsightSelectors* = Call_GetInsightSelectors_600034(
    name: "getInsightSelectors", meth: HttpMethod.HttpPost,
    host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetInsightSelectors",
    validator: validate_GetInsightSelectors_600035, base: "/",
    url: url_GetInsightSelectors_600036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrail_600049 = ref object of OpenApiRestCall_599368
proc url_GetTrail_600051(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTrail_600050(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns settings information for a specified trail.
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
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrail"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_GetTrail_600049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns settings information for a specified trail.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_GetTrail_600049; body: JsonNode): Recallable =
  ## getTrail
  ## Returns settings information for a specified trail.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var getTrail* = Call_GetTrail_600049(name: "getTrail", meth: HttpMethod.HttpPost,
                                  host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrail",
                                  validator: validate_GetTrail_600050, base: "/",
                                  url: url_GetTrail_600051,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTrailStatus_600064 = ref object of OpenApiRestCall_599368
proc url_GetTrailStatus_600066(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTrailStatus_600065(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns a JSON-formatted list of information about the specified trail. Fields include information on delivery errors, Amazon SNS and Amazon S3 errors, and start and stop logging times for each trail. This operation returns trail status from a single region. To return trail status from all regions, you must call the operation on each region.
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrailStatus"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_GetTrailStatus_600064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a JSON-formatted list of information about the specified trail. Fields include information on delivery errors, Amazon SNS and Amazon S3 errors, and start and stop logging times for each trail. This operation returns trail status from a single region. To return trail status from all regions, you must call the operation on each region.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_GetTrailStatus_600064; body: JsonNode): Recallable =
  ## getTrailStatus
  ## Returns a JSON-formatted list of information about the specified trail. Fields include information on delivery errors, Amazon SNS and Amazon S3 errors, and start and stop logging times for each trail. This operation returns trail status from a single region. To return trail status from all regions, you must call the operation on each region.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var getTrailStatus* = Call_GetTrailStatus_600064(name: "getTrailStatus",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.GetTrailStatus",
    validator: validate_GetTrailStatus_600065, base: "/", url: url_GetTrailStatus_600066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListPublicKeys_600079 = ref object of OpenApiRestCall_599368
proc url_ListPublicKeys_600081(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListPublicKeys_600080(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns all public keys whose private keys were used to sign the digest files within the specified time range. The public key is needed to validate digest files that were signed with its corresponding private key.</p> <note> <p>CloudTrail uses different private/public key pairs per region. Each digest file is signed with a private key unique to its region. Therefore, when you validate a digest file from a particular region, you must look in the same region for its corresponding public key.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600082 = query.getOrDefault("NextToken")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "NextToken", valid_600082
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
  var valid_600083 = header.getOrDefault("X-Amz-Date")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Date", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Security-Token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Security-Token", valid_600084
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600085 = header.getOrDefault("X-Amz-Target")
  valid_600085 = validateParameter(valid_600085, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListPublicKeys"))
  if valid_600085 != nil:
    section.add "X-Amz-Target", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Content-Sha256", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Algorithm")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Algorithm", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Signature")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Signature", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-SignedHeaders", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Credential")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Credential", valid_600090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600092: Call_ListPublicKeys_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all public keys whose private keys were used to sign the digest files within the specified time range. The public key is needed to validate digest files that were signed with its corresponding private key.</p> <note> <p>CloudTrail uses different private/public key pairs per region. Each digest file is signed with a private key unique to its region. Therefore, when you validate a digest file from a particular region, you must look in the same region for its corresponding public key.</p> </note>
  ## 
  let valid = call_600092.validator(path, query, header, formData, body)
  let scheme = call_600092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600092.url(scheme.get, call_600092.host, call_600092.base,
                         call_600092.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600092, url, valid)

proc call*(call_600093: Call_ListPublicKeys_600079; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listPublicKeys
  ## <p>Returns all public keys whose private keys were used to sign the digest files within the specified time range. The public key is needed to validate digest files that were signed with its corresponding private key.</p> <note> <p>CloudTrail uses different private/public key pairs per region. Each digest file is signed with a private key unique to its region. Therefore, when you validate a digest file from a particular region, you must look in the same region for its corresponding public key.</p> </note>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600094 = newJObject()
  var body_600095 = newJObject()
  add(query_600094, "NextToken", newJString(NextToken))
  if body != nil:
    body_600095 = body
  result = call_600093.call(nil, query_600094, nil, nil, body_600095)

var listPublicKeys* = Call_ListPublicKeys_600079(name: "listPublicKeys",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListPublicKeys",
    validator: validate_ListPublicKeys_600080, base: "/", url: url_ListPublicKeys_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_600097 = ref object of OpenApiRestCall_599368
proc url_ListTags_600099(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_600098(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the tags for the trail in the current region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600100 = query.getOrDefault("NextToken")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "NextToken", valid_600100
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
  var valid_600101 = header.getOrDefault("X-Amz-Date")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Date", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Security-Token")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Security-Token", valid_600102
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600103 = header.getOrDefault("X-Amz-Target")
  valid_600103 = validateParameter(valid_600103, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTags"))
  if valid_600103 != nil:
    section.add "X-Amz-Target", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Content-Sha256", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Algorithm")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Algorithm", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Signature")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Signature", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-SignedHeaders", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Credential")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Credential", valid_600108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600110: Call_ListTags_600097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags for the trail in the current region.
  ## 
  let valid = call_600110.validator(path, query, header, formData, body)
  let scheme = call_600110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600110.url(scheme.get, call_600110.host, call_600110.base,
                         call_600110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600110, url, valid)

proc call*(call_600111: Call_ListTags_600097; body: JsonNode; NextToken: string = ""): Recallable =
  ## listTags
  ## Lists the tags for the trail in the current region.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600112 = newJObject()
  var body_600113 = newJObject()
  add(query_600112, "NextToken", newJString(NextToken))
  if body != nil:
    body_600113 = body
  result = call_600111.call(nil, query_600112, nil, nil, body_600113)

var listTags* = Call_ListTags_600097(name: "listTags", meth: HttpMethod.HttpPost,
                                  host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTags",
                                  validator: validate_ListTags_600098, base: "/",
                                  url: url_ListTags_600099,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTrails_600114 = ref object of OpenApiRestCall_599368
proc url_ListTrails_600116(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTrails_600115(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists trails that are in the current account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_600117 = query.getOrDefault("NextToken")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "NextToken", valid_600117
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
  var valid_600118 = header.getOrDefault("X-Amz-Date")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Date", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Security-Token")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Security-Token", valid_600119
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600120 = header.getOrDefault("X-Amz-Target")
  valid_600120 = validateParameter(valid_600120, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTrails"))
  if valid_600120 != nil:
    section.add "X-Amz-Target", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Content-Sha256", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Algorithm")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Algorithm", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Signature")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Signature", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-SignedHeaders", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Credential")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Credential", valid_600125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600127: Call_ListTrails_600114; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists trails that are in the current account.
  ## 
  let valid = call_600127.validator(path, query, header, formData, body)
  let scheme = call_600127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600127.url(scheme.get, call_600127.host, call_600127.base,
                         call_600127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600127, url, valid)

proc call*(call_600128: Call_ListTrails_600114; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## listTrails
  ## Lists trails that are in the current account.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_600129 = newJObject()
  var body_600130 = newJObject()
  add(query_600129, "NextToken", newJString(NextToken))
  if body != nil:
    body_600130 = body
  result = call_600128.call(nil, query_600129, nil, nil, body_600130)

var listTrails* = Call_ListTrails_600114(name: "listTrails",
                                      meth: HttpMethod.HttpPost,
                                      host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.ListTrails",
                                      validator: validate_ListTrails_600115,
                                      base: "/", url: url_ListTrails_600116,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_LookupEvents_600131 = ref object of OpenApiRestCall_599368
proc url_LookupEvents_600133(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LookupEvents_600132(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Looks up <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-management-events">management events</a> or <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-insights-events">CloudTrail Insights events</a> that are captured by CloudTrail. You can look up events that occurred in a region within the last 90 days. Lookup supports the following attributes for management events:</p> <ul> <li> <p>AWS access key</p> </li> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> <li> <p>Read only</p> </li> <li> <p>Resource name</p> </li> <li> <p>Resource type</p> </li> <li> <p>User name</p> </li> </ul> <p>Lookup supports the following attributes for Insights events:</p> <ul> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> </ul> <p>All attributes are optional. The default number of results returned is 50, with a maximum of 50 possible. The response includes a token that you can use to get the next page of results.</p> <important> <p>The rate of lookup requests is limited to two per second per account. If this limit is exceeded, a throttling error occurs.</p> </important>
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
  var valid_600134 = query.getOrDefault("NextToken")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "NextToken", valid_600134
  var valid_600135 = query.getOrDefault("MaxResults")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "MaxResults", valid_600135
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
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600138 = header.getOrDefault("X-Amz-Target")
  valid_600138 = validateParameter(valid_600138, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.LookupEvents"))
  if valid_600138 != nil:
    section.add "X-Amz-Target", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Content-Sha256", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Algorithm")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Algorithm", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Signature")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Signature", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-SignedHeaders", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Credential")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Credential", valid_600143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600145: Call_LookupEvents_600131; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Looks up <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-management-events">management events</a> or <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-insights-events">CloudTrail Insights events</a> that are captured by CloudTrail. You can look up events that occurred in a region within the last 90 days. Lookup supports the following attributes for management events:</p> <ul> <li> <p>AWS access key</p> </li> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> <li> <p>Read only</p> </li> <li> <p>Resource name</p> </li> <li> <p>Resource type</p> </li> <li> <p>User name</p> </li> </ul> <p>Lookup supports the following attributes for Insights events:</p> <ul> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> </ul> <p>All attributes are optional. The default number of results returned is 50, with a maximum of 50 possible. The response includes a token that you can use to get the next page of results.</p> <important> <p>The rate of lookup requests is limited to two per second per account. If this limit is exceeded, a throttling error occurs.</p> </important>
  ## 
  let valid = call_600145.validator(path, query, header, formData, body)
  let scheme = call_600145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600145.url(scheme.get, call_600145.host, call_600145.base,
                         call_600145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600145, url, valid)

proc call*(call_600146: Call_LookupEvents_600131; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## lookupEvents
  ## <p>Looks up <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-management-events">management events</a> or <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html#cloudtrail-concepts-insights-events">CloudTrail Insights events</a> that are captured by CloudTrail. You can look up events that occurred in a region within the last 90 days. Lookup supports the following attributes for management events:</p> <ul> <li> <p>AWS access key</p> </li> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> <li> <p>Read only</p> </li> <li> <p>Resource name</p> </li> <li> <p>Resource type</p> </li> <li> <p>User name</p> </li> </ul> <p>Lookup supports the following attributes for Insights events:</p> <ul> <li> <p>Event ID</p> </li> <li> <p>Event name</p> </li> <li> <p>Event source</p> </li> </ul> <p>All attributes are optional. The default number of results returned is 50, with a maximum of 50 possible. The response includes a token that you can use to get the next page of results.</p> <important> <p>The rate of lookup requests is limited to two per second per account. If this limit is exceeded, a throttling error occurs.</p> </important>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600147 = newJObject()
  var body_600148 = newJObject()
  add(query_600147, "NextToken", newJString(NextToken))
  if body != nil:
    body_600148 = body
  add(query_600147, "MaxResults", newJString(MaxResults))
  result = call_600146.call(nil, query_600147, nil, nil, body_600148)

var lookupEvents* = Call_LookupEvents_600131(name: "lookupEvents",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.LookupEvents",
    validator: validate_LookupEvents_600132, base: "/", url: url_LookupEvents_600133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEventSelectors_600149 = ref object of OpenApiRestCall_599368
proc url_PutEventSelectors_600151(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutEventSelectors_600150(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Configures an event selector for your trail. Use event selectors to further specify the management and data event settings for your trail. By default, trails created without specific event selectors will be configured to log all read and write management events, and no data events. </p> <p>When an event occurs in your account, CloudTrail evaluates the event selectors in all trails. For each trail, if the event matches any event selector, the trail processes and logs the event. If the event doesn't match any event selector, the trail doesn't log the event. </p> <p>Example</p> <ol> <li> <p>You create an event selector for a trail and specify that you want write-only events.</p> </li> <li> <p>The EC2 <code>GetConsoleOutput</code> and <code>RunInstances</code> API operations occur in your account.</p> </li> <li> <p>CloudTrail evaluates whether the events match your event selectors.</p> </li> <li> <p>The <code>RunInstances</code> is a write-only event and it matches your event selector. The trail logs the event.</p> </li> <li> <p>The <code>GetConsoleOutput</code> is a read-only event but it doesn't match your event selector. The trail doesn't log the event. </p> </li> </ol> <p>The <code>PutEventSelectors</code> operation must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.</p> <p>You can configure up to five event selectors for each trail. For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> and <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html">Limits in AWS CloudTrail</a> in the <i>AWS CloudTrail User Guide</i>.</p>
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
  var valid_600152 = header.getOrDefault("X-Amz-Date")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Date", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Security-Token")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Security-Token", valid_600153
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600154 = header.getOrDefault("X-Amz-Target")
  valid_600154 = validateParameter(valid_600154, JString, required = true, default = newJString("com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutEventSelectors"))
  if valid_600154 != nil:
    section.add "X-Amz-Target", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Content-Sha256", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Algorithm")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Algorithm", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Signature")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Signature", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-SignedHeaders", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Credential")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Credential", valid_600159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600161: Call_PutEventSelectors_600149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures an event selector for your trail. Use event selectors to further specify the management and data event settings for your trail. By default, trails created without specific event selectors will be configured to log all read and write management events, and no data events. </p> <p>When an event occurs in your account, CloudTrail evaluates the event selectors in all trails. For each trail, if the event matches any event selector, the trail processes and logs the event. If the event doesn't match any event selector, the trail doesn't log the event. </p> <p>Example</p> <ol> <li> <p>You create an event selector for a trail and specify that you want write-only events.</p> </li> <li> <p>The EC2 <code>GetConsoleOutput</code> and <code>RunInstances</code> API operations occur in your account.</p> </li> <li> <p>CloudTrail evaluates whether the events match your event selectors.</p> </li> <li> <p>The <code>RunInstances</code> is a write-only event and it matches your event selector. The trail logs the event.</p> </li> <li> <p>The <code>GetConsoleOutput</code> is a read-only event but it doesn't match your event selector. The trail doesn't log the event. </p> </li> </ol> <p>The <code>PutEventSelectors</code> operation must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.</p> <p>You can configure up to five event selectors for each trail. For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> and <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html">Limits in AWS CloudTrail</a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ## 
  let valid = call_600161.validator(path, query, header, formData, body)
  let scheme = call_600161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600161.url(scheme.get, call_600161.host, call_600161.base,
                         call_600161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600161, url, valid)

proc call*(call_600162: Call_PutEventSelectors_600149; body: JsonNode): Recallable =
  ## putEventSelectors
  ## <p>Configures an event selector for your trail. Use event selectors to further specify the management and data event settings for your trail. By default, trails created without specific event selectors will be configured to log all read and write management events, and no data events. </p> <p>When an event occurs in your account, CloudTrail evaluates the event selectors in all trails. For each trail, if the event matches any event selector, the trail processes and logs the event. If the event doesn't match any event selector, the trail doesn't log the event. </p> <p>Example</p> <ol> <li> <p>You create an event selector for a trail and specify that you want write-only events.</p> </li> <li> <p>The EC2 <code>GetConsoleOutput</code> and <code>RunInstances</code> API operations occur in your account.</p> </li> <li> <p>CloudTrail evaluates whether the events match your event selectors.</p> </li> <li> <p>The <code>RunInstances</code> is a write-only event and it matches your event selector. The trail logs the event.</p> </li> <li> <p>The <code>GetConsoleOutput</code> is a read-only event but it doesn't match your event selector. The trail doesn't log the event. </p> </li> </ol> <p>The <code>PutEventSelectors</code> operation must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.</p> <p>You can configure up to five event selectors for each trail. For more information, see <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-and-data-events-with-cloudtrail.html">Logging Data and Management Events for Trails </a> and <a href="https://docs.aws.amazon.com/awscloudtrail/latest/userguide/WhatIsCloudTrail-Limits.html">Limits in AWS CloudTrail</a> in the <i>AWS CloudTrail User Guide</i>.</p>
  ##   body: JObject (required)
  var body_600163 = newJObject()
  if body != nil:
    body_600163 = body
  result = call_600162.call(nil, nil, nil, nil, body_600163)

var putEventSelectors* = Call_PutEventSelectors_600149(name: "putEventSelectors",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutEventSelectors",
    validator: validate_PutEventSelectors_600150, base: "/",
    url: url_PutEventSelectors_600151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInsightSelectors_600164 = ref object of OpenApiRestCall_599368
proc url_PutInsightSelectors_600166(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInsightSelectors_600165(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lets you enable Insights event logging by specifying the Insights selectors that you want to enable on an existing trail. You also use <code>PutInsightSelectors</code> to turn off Insights event logging, by passing an empty list of insight types. In this release, only <code>ApiCallRateInsight</code> is supported as an Insights selector.
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
  var valid_600167 = header.getOrDefault("X-Amz-Date")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Date", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Security-Token")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Security-Token", valid_600168
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600169 = header.getOrDefault("X-Amz-Target")
  valid_600169 = validateParameter(valid_600169, JString, required = true, default = newJString("com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutInsightSelectors"))
  if valid_600169 != nil:
    section.add "X-Amz-Target", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Content-Sha256", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Algorithm")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Algorithm", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Signature")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Signature", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-SignedHeaders", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Credential")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Credential", valid_600174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600176: Call_PutInsightSelectors_600164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lets you enable Insights event logging by specifying the Insights selectors that you want to enable on an existing trail. You also use <code>PutInsightSelectors</code> to turn off Insights event logging, by passing an empty list of insight types. In this release, only <code>ApiCallRateInsight</code> is supported as an Insights selector.
  ## 
  let valid = call_600176.validator(path, query, header, formData, body)
  let scheme = call_600176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600176.url(scheme.get, call_600176.host, call_600176.base,
                         call_600176.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600176, url, valid)

proc call*(call_600177: Call_PutInsightSelectors_600164; body: JsonNode): Recallable =
  ## putInsightSelectors
  ## Lets you enable Insights event logging by specifying the Insights selectors that you want to enable on an existing trail. You also use <code>PutInsightSelectors</code> to turn off Insights event logging, by passing an empty list of insight types. In this release, only <code>ApiCallRateInsight</code> is supported as an Insights selector.
  ##   body: JObject (required)
  var body_600178 = newJObject()
  if body != nil:
    body_600178 = body
  result = call_600177.call(nil, nil, nil, nil, body_600178)

var putInsightSelectors* = Call_PutInsightSelectors_600164(
    name: "putInsightSelectors", meth: HttpMethod.HttpPost,
    host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.PutInsightSelectors",
    validator: validate_PutInsightSelectors_600165, base: "/",
    url: url_PutInsightSelectors_600166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_600179 = ref object of OpenApiRestCall_599368
proc url_RemoveTags_600181(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTags_600180(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tags from a trail.
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
  var valid_600182 = header.getOrDefault("X-Amz-Date")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Date", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Security-Token")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Security-Token", valid_600183
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600184 = header.getOrDefault("X-Amz-Target")
  valid_600184 = validateParameter(valid_600184, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RemoveTags"))
  if valid_600184 != nil:
    section.add "X-Amz-Target", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Content-Sha256", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Algorithm")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Algorithm", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Signature")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Signature", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-SignedHeaders", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Credential")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Credential", valid_600189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600191: Call_RemoveTags_600179; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tags from a trail.
  ## 
  let valid = call_600191.validator(path, query, header, formData, body)
  let scheme = call_600191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600191.url(scheme.get, call_600191.host, call_600191.base,
                         call_600191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600191, url, valid)

proc call*(call_600192: Call_RemoveTags_600179; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified tags from a trail.
  ##   body: JObject (required)
  var body_600193 = newJObject()
  if body != nil:
    body_600193 = body
  result = call_600192.call(nil, nil, nil, nil, body_600193)

var removeTags* = Call_RemoveTags_600179(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.RemoveTags",
                                      validator: validate_RemoveTags_600180,
                                      base: "/", url: url_RemoveTags_600181,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartLogging_600194 = ref object of OpenApiRestCall_599368
proc url_StartLogging_600196(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartLogging_600195(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts the recording of AWS API calls and log file delivery for a trail. For a trail that is enabled in all regions, this operation must be called from the region in which the trail was created. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
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
  var valid_600197 = header.getOrDefault("X-Amz-Date")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Date", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Security-Token")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Security-Token", valid_600198
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600199 = header.getOrDefault("X-Amz-Target")
  valid_600199 = validateParameter(valid_600199, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartLogging"))
  if valid_600199 != nil:
    section.add "X-Amz-Target", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Content-Sha256", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Algorithm")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Algorithm", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Signature")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Signature", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-SignedHeaders", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Credential")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Credential", valid_600204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600206: Call_StartLogging_600194; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts the recording of AWS API calls and log file delivery for a trail. For a trail that is enabled in all regions, this operation must be called from the region in which the trail was created. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ## 
  let valid = call_600206.validator(path, query, header, formData, body)
  let scheme = call_600206.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600206.url(scheme.get, call_600206.host, call_600206.base,
                         call_600206.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600206, url, valid)

proc call*(call_600207: Call_StartLogging_600194; body: JsonNode): Recallable =
  ## startLogging
  ## Starts the recording of AWS API calls and log file delivery for a trail. For a trail that is enabled in all regions, this operation must be called from the region in which the trail was created. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail that is enabled in all regions.
  ##   body: JObject (required)
  var body_600208 = newJObject()
  if body != nil:
    body_600208 = body
  result = call_600207.call(nil, nil, nil, nil, body_600208)

var startLogging* = Call_StartLogging_600194(name: "startLogging",
    meth: HttpMethod.HttpPost, host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StartLogging",
    validator: validate_StartLogging_600195, base: "/", url: url_StartLogging_600196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopLogging_600209 = ref object of OpenApiRestCall_599368
proc url_StopLogging_600211(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopLogging_600210(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Suspends the recording of AWS API calls and log file delivery for the specified trail. Under most circumstances, there is no need to use this action. You can update a trail without stopping it first. This action is the only way to stop recording. For a trail enabled in all regions, this operation must be called from the region in which the trail was created, or an <code>InvalidHomeRegionException</code> will occur. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail enabled in all regions.
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
  var valid_600212 = header.getOrDefault("X-Amz-Date")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Date", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Security-Token")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Security-Token", valid_600213
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600214 = header.getOrDefault("X-Amz-Target")
  valid_600214 = validateParameter(valid_600214, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopLogging"))
  if valid_600214 != nil:
    section.add "X-Amz-Target", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Content-Sha256", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Algorithm")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Algorithm", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-Signature")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Signature", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-SignedHeaders", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Credential")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Credential", valid_600219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600221: Call_StopLogging_600209; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Suspends the recording of AWS API calls and log file delivery for the specified trail. Under most circumstances, there is no need to use this action. You can update a trail without stopping it first. This action is the only way to stop recording. For a trail enabled in all regions, this operation must be called from the region in which the trail was created, or an <code>InvalidHomeRegionException</code> will occur. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail enabled in all regions.
  ## 
  let valid = call_600221.validator(path, query, header, formData, body)
  let scheme = call_600221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600221.url(scheme.get, call_600221.host, call_600221.base,
                         call_600221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600221, url, valid)

proc call*(call_600222: Call_StopLogging_600209; body: JsonNode): Recallable =
  ## stopLogging
  ## Suspends the recording of AWS API calls and log file delivery for the specified trail. Under most circumstances, there is no need to use this action. You can update a trail without stopping it first. This action is the only way to stop recording. For a trail enabled in all regions, this operation must be called from the region in which the trail was created, or an <code>InvalidHomeRegionException</code> will occur. This operation cannot be called on the shadow trails (replicated trails in other regions) of a trail enabled in all regions.
  ##   body: JObject (required)
  var body_600223 = newJObject()
  if body != nil:
    body_600223 = body
  result = call_600222.call(nil, nil, nil, nil, body_600223)

var stopLogging* = Call_StopLogging_600209(name: "stopLogging",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.StopLogging",
                                        validator: validate_StopLogging_600210,
                                        base: "/", url: url_StopLogging_600211,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTrail_600224 = ref object of OpenApiRestCall_599368
proc url_UpdateTrail_600226(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateTrail_600225(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the settings that specify delivery of log files. Changes to a trail do not require stopping the CloudTrail service. Use this action to designate an existing bucket for log delivery. If the existing bucket has previously been a target for CloudTrail log files, an IAM policy exists for the bucket. <code>UpdateTrail</code> must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.
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
  var valid_600227 = header.getOrDefault("X-Amz-Date")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Date", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Security-Token")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Security-Token", valid_600228
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600229 = header.getOrDefault("X-Amz-Target")
  valid_600229 = validateParameter(valid_600229, JString, required = true, default = newJString(
      "com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateTrail"))
  if valid_600229 != nil:
    section.add "X-Amz-Target", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Content-Sha256", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-Algorithm")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-Algorithm", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Signature")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Signature", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-SignedHeaders", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Credential")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Credential", valid_600234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600236: Call_UpdateTrail_600224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the settings that specify delivery of log files. Changes to a trail do not require stopping the CloudTrail service. Use this action to designate an existing bucket for log delivery. If the existing bucket has previously been a target for CloudTrail log files, an IAM policy exists for the bucket. <code>UpdateTrail</code> must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.
  ## 
  let valid = call_600236.validator(path, query, header, formData, body)
  let scheme = call_600236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600236.url(scheme.get, call_600236.host, call_600236.base,
                         call_600236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600236, url, valid)

proc call*(call_600237: Call_UpdateTrail_600224; body: JsonNode): Recallable =
  ## updateTrail
  ## Updates the settings that specify delivery of log files. Changes to a trail do not require stopping the CloudTrail service. Use this action to designate an existing bucket for log delivery. If the existing bucket has previously been a target for CloudTrail log files, an IAM policy exists for the bucket. <code>UpdateTrail</code> must be called from the region in which the trail was created; otherwise, an <code>InvalidHomeRegionException</code> is thrown.
  ##   body: JObject (required)
  var body_600238 = newJObject()
  if body != nil:
    body_600238 = body
  result = call_600237.call(nil, nil, nil, nil, body_600238)

var updateTrail* = Call_UpdateTrail_600224(name: "updateTrail",
                                        meth: HttpMethod.HttpPost,
                                        host: "cloudtrail.amazonaws.com", route: "/#X-Amz-Target=com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101.UpdateTrail",
                                        validator: validate_UpdateTrail_600225,
                                        base: "/", url: url_UpdateTrail_600226,
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
