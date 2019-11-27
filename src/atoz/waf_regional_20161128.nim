
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS WAF Regional
## version: 2016-11-28
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This is the <i>AWS WAF Regional API Reference</i> for using AWS WAF with Elastic Load Balancing (ELB) Application Load Balancers. The AWS WAF actions and data types listed in the reference are available for protecting Application Load Balancers. You can use these actions and data types by means of the endpoints listed in <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#waf_region">AWS Regions and Endpoints</a>. This guide is for developers who need detailed information about the AWS WAF API actions, data types, and errors. For detailed information about AWS WAF features and an overview of how to use the AWS WAF API, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/waf-regional/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "waf-regional.ap-northeast-1.amazonaws.com", "ap-southeast-1": "waf-regional.ap-southeast-1.amazonaws.com",
                           "us-west-2": "waf-regional.us-west-2.amazonaws.com",
                           "eu-west-2": "waf-regional.eu-west-2.amazonaws.com", "ap-northeast-3": "waf-regional.ap-northeast-3.amazonaws.com", "eu-central-1": "waf-regional.eu-central-1.amazonaws.com",
                           "us-east-2": "waf-regional.us-east-2.amazonaws.com",
                           "us-east-1": "waf-regional.us-east-1.amazonaws.com", "cn-northwest-1": "waf-regional.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "waf-regional.ap-south-1.amazonaws.com", "eu-north-1": "waf-regional.eu-north-1.amazonaws.com", "ap-northeast-2": "waf-regional.ap-northeast-2.amazonaws.com",
                           "us-west-1": "waf-regional.us-west-1.amazonaws.com", "us-gov-east-1": "waf-regional.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "waf-regional.eu-west-3.amazonaws.com", "cn-north-1": "waf-regional.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "waf-regional.sa-east-1.amazonaws.com",
                           "eu-west-1": "waf-regional.eu-west-1.amazonaws.com", "us-gov-west-1": "waf-regional.us-gov-west-1.amazonaws.com", "ap-southeast-2": "waf-regional.ap-southeast-2.amazonaws.com", "ca-central-1": "waf-regional.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "waf-regional.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "waf-regional.ap-southeast-1.amazonaws.com",
      "us-west-2": "waf-regional.us-west-2.amazonaws.com",
      "eu-west-2": "waf-regional.eu-west-2.amazonaws.com",
      "ap-northeast-3": "waf-regional.ap-northeast-3.amazonaws.com",
      "eu-central-1": "waf-regional.eu-central-1.amazonaws.com",
      "us-east-2": "waf-regional.us-east-2.amazonaws.com",
      "us-east-1": "waf-regional.us-east-1.amazonaws.com",
      "cn-northwest-1": "waf-regional.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "waf-regional.ap-south-1.amazonaws.com",
      "eu-north-1": "waf-regional.eu-north-1.amazonaws.com",
      "ap-northeast-2": "waf-regional.ap-northeast-2.amazonaws.com",
      "us-west-1": "waf-regional.us-west-1.amazonaws.com",
      "us-gov-east-1": "waf-regional.us-gov-east-1.amazonaws.com",
      "eu-west-3": "waf-regional.eu-west-3.amazonaws.com",
      "cn-north-1": "waf-regional.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "waf-regional.sa-east-1.amazonaws.com",
      "eu-west-1": "waf-regional.eu-west-1.amazonaws.com",
      "us-gov-west-1": "waf-regional.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "waf-regional.ap-southeast-2.amazonaws.com",
      "ca-central-1": "waf-regional.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "waf-regional"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateWebACL_599705 = ref object of OpenApiRestCall_599368
proc url_AssociateWebACL_599707(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateWebACL_599706(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Associates a web ACL with a resource, either an application load balancer or Amazon API Gateway stage.
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
      "AWSWAF_Regional_20161128.AssociateWebACL"))
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

proc call*(call_599863: Call_AssociateWebACL_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a web ACL with a resource, either an application load balancer or Amazon API Gateway stage.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_AssociateWebACL_599705; body: JsonNode): Recallable =
  ## associateWebACL
  ## Associates a web ACL with a resource, either an application load balancer or Amazon API Gateway stage.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var associateWebACL* = Call_AssociateWebACL_599705(name: "associateWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.AssociateWebACL",
    validator: validate_AssociateWebACL_599706, base: "/", url: url_AssociateWebACL_599707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateByteMatchSet_599974 = ref object of OpenApiRestCall_599368
proc url_CreateByteMatchSet_599976(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateByteMatchSet_599975(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a <code>ByteMatchSet</code>. You then use <a>UpdateByteMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>ByteMatchSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>BadBot</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateByteMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
      "AWSWAF_Regional_20161128.CreateByteMatchSet"))
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

proc call*(call_599986: Call_CreateByteMatchSet_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>ByteMatchSet</code>. You then use <a>UpdateByteMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>ByteMatchSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>BadBot</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateByteMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CreateByteMatchSet_599974; body: JsonNode): Recallable =
  ## createByteMatchSet
  ## <p>Creates a <code>ByteMatchSet</code>. You then use <a>UpdateByteMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>ByteMatchSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>BadBot</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateByteMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var createByteMatchSet* = Call_CreateByteMatchSet_599974(
    name: "createByteMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateByteMatchSet",
    validator: validate_CreateByteMatchSet_599975, base: "/",
    url: url_CreateByteMatchSet_599976, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGeoMatchSet_599989 = ref object of OpenApiRestCall_599368
proc url_CreateGeoMatchSet_599991(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGeoMatchSet_599990(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an <a>GeoMatchSet</a>, which you use to specify which web requests you want to allow or block based on the country that the requests originate from. For example, if you're receiving a lot of requests from one or more countries and you want to block the requests, you can create an <code>GeoMatchSet</code> that contains those countries and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSetSet</code> request to specify the countries that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
      "AWSWAF_Regional_20161128.CreateGeoMatchSet"))
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

proc call*(call_600001: Call_CreateGeoMatchSet_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a>GeoMatchSet</a>, which you use to specify which web requests you want to allow or block based on the country that the requests originate from. For example, if you're receiving a lot of requests from one or more countries and you want to block the requests, you can create an <code>GeoMatchSet</code> that contains those countries and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSetSet</code> request to specify the countries that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_CreateGeoMatchSet_599989; body: JsonNode): Recallable =
  ## createGeoMatchSet
  ## <p>Creates an <a>GeoMatchSet</a>, which you use to specify which web requests you want to allow or block based on the country that the requests originate from. For example, if you're receiving a lot of requests from one or more countries and you want to block the requests, you can create an <code>GeoMatchSet</code> that contains those countries and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSetSet</code> request to specify the countries that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var createGeoMatchSet* = Call_CreateGeoMatchSet_599989(name: "createGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateGeoMatchSet",
    validator: validate_CreateGeoMatchSet_599990, base: "/",
    url: url_CreateGeoMatchSet_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_600004 = ref object of OpenApiRestCall_599368
proc url_CreateIPSet_600006(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateIPSet_600005(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an <a>IPSet</a>, which you use to specify which web requests that you want to allow or block based on the IP addresses that the requests originate from. For example, if you're receiving a lot of requests from one or more individual IP addresses or one or more ranges of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that contains those IP addresses and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateIPSet</code> request.</p> </li> <li> <p>Submit a <code>CreateIPSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
      "AWSWAF_Regional_20161128.CreateIPSet"))
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

proc call*(call_600016: Call_CreateIPSet_600004; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a>IPSet</a>, which you use to specify which web requests that you want to allow or block based on the IP addresses that the requests originate from. For example, if you're receiving a lot of requests from one or more individual IP addresses or one or more ranges of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that contains those IP addresses and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateIPSet</code> request.</p> </li> <li> <p>Submit a <code>CreateIPSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_CreateIPSet_600004; body: JsonNode): Recallable =
  ## createIPSet
  ## <p>Creates an <a>IPSet</a>, which you use to specify which web requests that you want to allow or block based on the IP addresses that the requests originate from. For example, if you're receiving a lot of requests from one or more individual IP addresses or one or more ranges of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that contains those IP addresses and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateIPSet</code> request.</p> </li> <li> <p>Submit a <code>CreateIPSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var createIPSet* = Call_CreateIPSet_600004(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateIPSet",
                                        validator: validate_CreateIPSet_600005,
                                        base: "/", url: url_CreateIPSet_600006,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRateBasedRule_600019 = ref object of OpenApiRestCall_599368
proc url_CreateRateBasedRule_600021(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRateBasedRule_600020(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a <a>RateBasedRule</a>. The <code>RateBasedRule</code> contains a <code>RateLimit</code>, which specifies the maximum number of requests that AWS WAF allows from a specified IP address in a five-minute period. The <code>RateBasedRule</code> also contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to count or block if these requests exceed the <code>RateLimit</code>.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request not only must exceed the <code>RateLimit</code>, but it also must match all the specifications to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that meet the conditions in the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions must be received at a rate of more than 15,000 requests every five minutes. If both conditions are met and the rate is exceeded, AWS WAF blocks the requests. If the rate drops below 15,000 for a five-minute period, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p> <p>To create and configure a <code>RateBasedRule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the rule. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRateBasedRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRateBasedRule</code> request to specify the predicates that you want to include in the rule.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RateBasedRule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRateBasedRule"))
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

proc call*(call_600031: Call_CreateRateBasedRule_600019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>RateBasedRule</a>. The <code>RateBasedRule</code> contains a <code>RateLimit</code>, which specifies the maximum number of requests that AWS WAF allows from a specified IP address in a five-minute period. The <code>RateBasedRule</code> also contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to count or block if these requests exceed the <code>RateLimit</code>.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request not only must exceed the <code>RateLimit</code>, but it also must match all the specifications to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that meet the conditions in the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions must be received at a rate of more than 15,000 requests every five minutes. If both conditions are met and the rate is exceeded, AWS WAF blocks the requests. If the rate drops below 15,000 for a five-minute period, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p> <p>To create and configure a <code>RateBasedRule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the rule. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRateBasedRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRateBasedRule</code> request to specify the predicates that you want to include in the rule.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RateBasedRule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_CreateRateBasedRule_600019; body: JsonNode): Recallable =
  ## createRateBasedRule
  ## <p>Creates a <a>RateBasedRule</a>. The <code>RateBasedRule</code> contains a <code>RateLimit</code>, which specifies the maximum number of requests that AWS WAF allows from a specified IP address in a five-minute period. The <code>RateBasedRule</code> also contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to count or block if these requests exceed the <code>RateLimit</code>.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request not only must exceed the <code>RateLimit</code>, but it also must match all the specifications to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that meet the conditions in the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions must be received at a rate of more than 15,000 requests every five minutes. If both conditions are met and the rate is exceeded, AWS WAF blocks the requests. If the rate drops below 15,000 for a five-minute period, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p> <p>To create and configure a <code>RateBasedRule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the rule. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRateBasedRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRateBasedRule</code> request to specify the predicates that you want to include in the rule.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RateBasedRule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var createRateBasedRule* = Call_CreateRateBasedRule_600019(
    name: "createRateBasedRule", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRateBasedRule",
    validator: validate_CreateRateBasedRule_600020, base: "/",
    url: url_CreateRateBasedRule_600021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegexMatchSet_600034 = ref object of OpenApiRestCall_599368
proc url_CreateRegexMatchSet_600036(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRegexMatchSet_600035(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a <a>RegexMatchSet</a>. You then use <a>UpdateRegexMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>RegexMatchSet</code> that contains a <code>RegexMatchTuple</code> that looks for any requests with <code>User-Agent</code> headers that match a <code>RegexPatternSet</code> with pattern <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value, using a <code>RegexPatternSet</code>, that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRegexMatchSet"))
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

proc call*(call_600046: Call_CreateRegexMatchSet_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>RegexMatchSet</a>. You then use <a>UpdateRegexMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>RegexMatchSet</code> that contains a <code>RegexMatchTuple</code> that looks for any requests with <code>User-Agent</code> headers that match a <code>RegexPatternSet</code> with pattern <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value, using a <code>RegexPatternSet</code>, that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_CreateRegexMatchSet_600034; body: JsonNode): Recallable =
  ## createRegexMatchSet
  ## <p>Creates a <a>RegexMatchSet</a>. You then use <a>UpdateRegexMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>RegexMatchSet</code> that contains a <code>RegexMatchTuple</code> that looks for any requests with <code>User-Agent</code> headers that match a <code>RegexPatternSet</code> with pattern <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value, using a <code>RegexPatternSet</code>, that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var createRegexMatchSet* = Call_CreateRegexMatchSet_600034(
    name: "createRegexMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRegexMatchSet",
    validator: validate_CreateRegexMatchSet_600035, base: "/",
    url: url_CreateRegexMatchSet_600036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegexPatternSet_600049 = ref object of OpenApiRestCall_599368
proc url_CreateRegexPatternSet_600051(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRegexPatternSet_600050(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>RegexPatternSet</code>. You then use <a>UpdateRegexPatternSet</a> to specify the regular expression (regex) pattern that you want AWS WAF to search for, such as <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexPatternSet</a> request to specify the string that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
      "AWSWAF_Regional_20161128.CreateRegexPatternSet"))
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

proc call*(call_600061: Call_CreateRegexPatternSet_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>RegexPatternSet</code>. You then use <a>UpdateRegexPatternSet</a> to specify the regular expression (regex) pattern that you want AWS WAF to search for, such as <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexPatternSet</a> request to specify the string that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_CreateRegexPatternSet_600049; body: JsonNode): Recallable =
  ## createRegexPatternSet
  ## <p>Creates a <code>RegexPatternSet</code>. You then use <a>UpdateRegexPatternSet</a> to specify the regular expression (regex) pattern that you want AWS WAF to search for, such as <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexPatternSet</a> request to specify the string that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var createRegexPatternSet* = Call_CreateRegexPatternSet_600049(
    name: "createRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRegexPatternSet",
    validator: validate_CreateRegexPatternSet_600050, base: "/",
    url: url_CreateRegexPatternSet_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRule_600064 = ref object of OpenApiRestCall_599368
proc url_CreateRule_600066(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRule_600065(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>Rule</code>, which contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to block. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed or blocked. For example, suppose that you add the following to a <code>Rule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to blocks requests that satisfy the <code>Rule</code>. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to specify the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
      "AWSWAF_Regional_20161128.CreateRule"))
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

proc call*(call_600076: Call_CreateRule_600064; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Rule</code>, which contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to block. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed or blocked. For example, suppose that you add the following to a <code>Rule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to blocks requests that satisfy the <code>Rule</code>. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to specify the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_CreateRule_600064; body: JsonNode): Recallable =
  ## createRule
  ## <p>Creates a <code>Rule</code>, which contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to block. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed or blocked. For example, suppose that you add the following to a <code>Rule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to blocks requests that satisfy the <code>Rule</code>. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to specify the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var createRule* = Call_CreateRule_600064(name: "createRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRule",
                                      validator: validate_CreateRule_600065,
                                      base: "/", url: url_CreateRule_600066,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRuleGroup_600079 = ref object of OpenApiRestCall_599368
proc url_CreateRuleGroup_600081(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRuleGroup_600080(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a <code>RuleGroup</code>. A rule group is a collection of predefined rules that you add to a web ACL. You use <a>UpdateRuleGroup</a> to add rules to the rule group.</p> <p>Rule groups are subject to the following limits:</p> <ul> <li> <p>Three rule groups per account. You can request an increase to this limit by contacting customer support.</p> </li> <li> <p>One rule group per web ACL.</p> </li> <li> <p>Ten rules per rule group.</p> </li> </ul> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRuleGroup"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_CreateRuleGroup_600079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>RuleGroup</code>. A rule group is a collection of predefined rules that you add to a web ACL. You use <a>UpdateRuleGroup</a> to add rules to the rule group.</p> <p>Rule groups are subject to the following limits:</p> <ul> <li> <p>Three rule groups per account. You can request an increase to this limit by contacting customer support.</p> </li> <li> <p>One rule group per web ACL.</p> </li> <li> <p>Ten rules per rule group.</p> </li> </ul> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_CreateRuleGroup_600079; body: JsonNode): Recallable =
  ## createRuleGroup
  ## <p>Creates a <code>RuleGroup</code>. A rule group is a collection of predefined rules that you add to a web ACL. You use <a>UpdateRuleGroup</a> to add rules to the rule group.</p> <p>Rule groups are subject to the following limits:</p> <ul> <li> <p>Three rule groups per account. You can request an increase to this limit by contacting customer support.</p> </li> <li> <p>One rule group per web ACL.</p> </li> <li> <p>Ten rules per rule group.</p> </li> </ul> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var createRuleGroup* = Call_CreateRuleGroup_600079(name: "createRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRuleGroup",
    validator: validate_CreateRuleGroup_600080, base: "/", url: url_CreateRuleGroup_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSizeConstraintSet_600094 = ref object of OpenApiRestCall_599368
proc url_CreateSizeConstraintSet_600096(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSizeConstraintSet_600095(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>SizeConstraintSet</code>. You then use <a>UpdateSizeConstraintSet</a> to identify the part of a web request that you want AWS WAF to check for length, such as the length of the <code>User-Agent</code> header or the length of the query string. For example, you can create a <code>SizeConstraintSet</code> that matches any requests that have a query string that is longer than 100 bytes. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateSizeConstraintSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateSizeConstraintSet"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_CreateSizeConstraintSet_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>SizeConstraintSet</code>. You then use <a>UpdateSizeConstraintSet</a> to identify the part of a web request that you want AWS WAF to check for length, such as the length of the <code>User-Agent</code> header or the length of the query string. For example, you can create a <code>SizeConstraintSet</code> that matches any requests that have a query string that is longer than 100 bytes. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateSizeConstraintSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_CreateSizeConstraintSet_600094; body: JsonNode): Recallable =
  ## createSizeConstraintSet
  ## <p>Creates a <code>SizeConstraintSet</code>. You then use <a>UpdateSizeConstraintSet</a> to identify the part of a web request that you want AWS WAF to check for length, such as the length of the <code>User-Agent</code> header or the length of the query string. For example, you can create a <code>SizeConstraintSet</code> that matches any requests that have a query string that is longer than 100 bytes. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateSizeConstraintSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var createSizeConstraintSet* = Call_CreateSizeConstraintSet_600094(
    name: "createSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateSizeConstraintSet",
    validator: validate_CreateSizeConstraintSet_600095, base: "/",
    url: url_CreateSizeConstraintSet_600096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSqlInjectionMatchSet_600109 = ref object of OpenApiRestCall_599368
proc url_CreateSqlInjectionMatchSet_600111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSqlInjectionMatchSet_600110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <a>SqlInjectionMatchSet</a>, which you use to allow, block, or count requests that contain snippets of SQL code in a specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateSqlInjectionMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count malicious SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateSqlInjectionMatchSet"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_CreateSqlInjectionMatchSet_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>SqlInjectionMatchSet</a>, which you use to allow, block, or count requests that contain snippets of SQL code in a specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateSqlInjectionMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count malicious SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_CreateSqlInjectionMatchSet_600109; body: JsonNode): Recallable =
  ## createSqlInjectionMatchSet
  ## <p>Creates a <a>SqlInjectionMatchSet</a>, which you use to allow, block, or count requests that contain snippets of SQL code in a specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateSqlInjectionMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count malicious SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var createSqlInjectionMatchSet* = Call_CreateSqlInjectionMatchSet_600109(
    name: "createSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateSqlInjectionMatchSet",
    validator: validate_CreateSqlInjectionMatchSet_600110, base: "/",
    url: url_CreateSqlInjectionMatchSet_600111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebACL_600124 = ref object of OpenApiRestCall_599368
proc url_CreateWebACL_600126(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateWebACL_600125(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a <code>WebACL</code>, which contains the <code>Rules</code> that identify the CloudFront web requests that you want to allow, block, or count. AWS WAF evaluates <code>Rules</code> in order based on the value of <code>Priority</code> for each <code>Rule</code>.</p> <p>You also specify a default action, either <code>ALLOW</code> or <code>BLOCK</code>. If a web request doesn't match any of the <code>Rules</code> in a <code>WebACL</code>, AWS WAF responds to the request with the default action. </p> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>ByteMatchSet</code> objects and other predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateWebACL</code> request.</p> </li> <li> <p>Submit a <code>CreateWebACL</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <a>UpdateWebACL</a> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution.</p> </li> </ol> <p>For more information about how to use the AWS WAF API, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateWebACL"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_CreateWebACL_600124; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>WebACL</code>, which contains the <code>Rules</code> that identify the CloudFront web requests that you want to allow, block, or count. AWS WAF evaluates <code>Rules</code> in order based on the value of <code>Priority</code> for each <code>Rule</code>.</p> <p>You also specify a default action, either <code>ALLOW</code> or <code>BLOCK</code>. If a web request doesn't match any of the <code>Rules</code> in a <code>WebACL</code>, AWS WAF responds to the request with the default action. </p> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>ByteMatchSet</code> objects and other predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateWebACL</code> request.</p> </li> <li> <p>Submit a <code>CreateWebACL</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <a>UpdateWebACL</a> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution.</p> </li> </ol> <p>For more information about how to use the AWS WAF API, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_CreateWebACL_600124; body: JsonNode): Recallable =
  ## createWebACL
  ## <p>Creates a <code>WebACL</code>, which contains the <code>Rules</code> that identify the CloudFront web requests that you want to allow, block, or count. AWS WAF evaluates <code>Rules</code> in order based on the value of <code>Priority</code> for each <code>Rule</code>.</p> <p>You also specify a default action, either <code>ALLOW</code> or <code>BLOCK</code>. If a web request doesn't match any of the <code>Rules</code> in a <code>WebACL</code>, AWS WAF responds to the request with the default action. </p> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>ByteMatchSet</code> objects and other predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateWebACL</code> request.</p> </li> <li> <p>Submit a <code>CreateWebACL</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <a>UpdateWebACL</a> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution.</p> </li> </ol> <p>For more information about how to use the AWS WAF API, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var createWebACL* = Call_CreateWebACL_600124(name: "createWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateWebACL",
    validator: validate_CreateWebACL_600125, base: "/", url: url_CreateWebACL_600126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateXssMatchSet_600139 = ref object of OpenApiRestCall_599368
proc url_CreateXssMatchSet_600141(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateXssMatchSet_600140(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Creates an <a>XssMatchSet</a>, which you use to allow, block, or count requests that contain cross-site scripting attacks in the specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateXssMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateXssMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateXssMatchSet"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_CreateXssMatchSet_600139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a>XssMatchSet</a>, which you use to allow, block, or count requests that contain cross-site scripting attacks in the specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateXssMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateXssMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_CreateXssMatchSet_600139; body: JsonNode): Recallable =
  ## createXssMatchSet
  ## <p>Creates an <a>XssMatchSet</a>, which you use to allow, block, or count requests that contain cross-site scripting attacks in the specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateXssMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateXssMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var createXssMatchSet* = Call_CreateXssMatchSet_600139(name: "createXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateXssMatchSet",
    validator: validate_CreateXssMatchSet_600140, base: "/",
    url: url_CreateXssMatchSet_600141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteByteMatchSet_600154 = ref object of OpenApiRestCall_599368
proc url_DeleteByteMatchSet_600156(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteByteMatchSet_600155(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>ByteMatchSet</a>. You can't delete a <code>ByteMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>ByteMatchTuple</a> objects (any filters).</p> <p>If you just want to remove a <code>ByteMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>ByteMatchSet</code> to remove filters, if any. For more information, see <a>UpdateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteByteMatchSet</code> request.</p> </li> </ol>
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteByteMatchSet"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_DeleteByteMatchSet_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>ByteMatchSet</a>. You can't delete a <code>ByteMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>ByteMatchTuple</a> objects (any filters).</p> <p>If you just want to remove a <code>ByteMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>ByteMatchSet</code> to remove filters, if any. For more information, see <a>UpdateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteByteMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_DeleteByteMatchSet_600154; body: JsonNode): Recallable =
  ## deleteByteMatchSet
  ## <p>Permanently deletes a <a>ByteMatchSet</a>. You can't delete a <code>ByteMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>ByteMatchTuple</a> objects (any filters).</p> <p>If you just want to remove a <code>ByteMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>ByteMatchSet</code> to remove filters, if any. For more information, see <a>UpdateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteByteMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var deleteByteMatchSet* = Call_DeleteByteMatchSet_600154(
    name: "deleteByteMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteByteMatchSet",
    validator: validate_DeleteByteMatchSet_600155, base: "/",
    url: url_DeleteByteMatchSet_600156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGeoMatchSet_600169 = ref object of OpenApiRestCall_599368
proc url_DeleteGeoMatchSet_600171(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGeoMatchSet_600170(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>GeoMatchSet</a>. You can't delete a <code>GeoMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any countries.</p> <p>If you just want to remove a <code>GeoMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>GeoMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>GeoMatchSet</code> to remove any countries. For more information, see <a>UpdateGeoMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteGeoMatchSet</code> request.</p> </li> </ol>
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
  var valid_600172 = header.getOrDefault("X-Amz-Date")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Date", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Security-Token")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Security-Token", valid_600173
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600174 = header.getOrDefault("X-Amz-Target")
  valid_600174 = validateParameter(valid_600174, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteGeoMatchSet"))
  if valid_600174 != nil:
    section.add "X-Amz-Target", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600181: Call_DeleteGeoMatchSet_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>GeoMatchSet</a>. You can't delete a <code>GeoMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any countries.</p> <p>If you just want to remove a <code>GeoMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>GeoMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>GeoMatchSet</code> to remove any countries. For more information, see <a>UpdateGeoMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteGeoMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_600181.validator(path, query, header, formData, body)
  let scheme = call_600181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600181.url(scheme.get, call_600181.host, call_600181.base,
                         call_600181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600181, url, valid)

proc call*(call_600182: Call_DeleteGeoMatchSet_600169; body: JsonNode): Recallable =
  ## deleteGeoMatchSet
  ## <p>Permanently deletes a <a>GeoMatchSet</a>. You can't delete a <code>GeoMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any countries.</p> <p>If you just want to remove a <code>GeoMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>GeoMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>GeoMatchSet</code> to remove any countries. For more information, see <a>UpdateGeoMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteGeoMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600183 = newJObject()
  if body != nil:
    body_600183 = body
  result = call_600182.call(nil, nil, nil, nil, body_600183)

var deleteGeoMatchSet* = Call_DeleteGeoMatchSet_600169(name: "deleteGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteGeoMatchSet",
    validator: validate_DeleteGeoMatchSet_600170, base: "/",
    url: url_DeleteGeoMatchSet_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_600184 = ref object of OpenApiRestCall_599368
proc url_DeleteIPSet_600186(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteIPSet_600185(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Permanently deletes an <a>IPSet</a>. You can't delete an <code>IPSet</code> if it's still used in any <code>Rules</code> or if it still includes any IP addresses.</p> <p>If you just want to remove an <code>IPSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>IPSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>IPSet</code> to remove IP address ranges, if any. For more information, see <a>UpdateIPSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteIPSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteIPSet</code> request.</p> </li> </ol>
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
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600189 = header.getOrDefault("X-Amz-Target")
  valid_600189 = validateParameter(valid_600189, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteIPSet"))
  if valid_600189 != nil:
    section.add "X-Amz-Target", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Content-Sha256", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Algorithm")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Algorithm", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Signature")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Signature", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-SignedHeaders", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Credential")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Credential", valid_600194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600196: Call_DeleteIPSet_600184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes an <a>IPSet</a>. You can't delete an <code>IPSet</code> if it's still used in any <code>Rules</code> or if it still includes any IP addresses.</p> <p>If you just want to remove an <code>IPSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>IPSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>IPSet</code> to remove IP address ranges, if any. For more information, see <a>UpdateIPSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteIPSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteIPSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_600196.validator(path, query, header, formData, body)
  let scheme = call_600196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600196.url(scheme.get, call_600196.host, call_600196.base,
                         call_600196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600196, url, valid)

proc call*(call_600197: Call_DeleteIPSet_600184; body: JsonNode): Recallable =
  ## deleteIPSet
  ## <p>Permanently deletes an <a>IPSet</a>. You can't delete an <code>IPSet</code> if it's still used in any <code>Rules</code> or if it still includes any IP addresses.</p> <p>If you just want to remove an <code>IPSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>IPSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>IPSet</code> to remove IP address ranges, if any. For more information, see <a>UpdateIPSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteIPSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteIPSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600198 = newJObject()
  if body != nil:
    body_600198 = body
  result = call_600197.call(nil, nil, nil, nil, body_600198)

var deleteIPSet* = Call_DeleteIPSet_600184(name: "deleteIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteIPSet",
                                        validator: validate_DeleteIPSet_600185,
                                        base: "/", url: url_DeleteIPSet_600186,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggingConfiguration_600199 = ref object of OpenApiRestCall_599368
proc url_DeleteLoggingConfiguration_600201(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLoggingConfiguration_600200(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently deletes the <a>LoggingConfiguration</a> from the specified web ACL.
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
  var valid_600202 = header.getOrDefault("X-Amz-Date")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Date", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Security-Token")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Security-Token", valid_600203
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600204 = header.getOrDefault("X-Amz-Target")
  valid_600204 = validateParameter(valid_600204, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteLoggingConfiguration"))
  if valid_600204 != nil:
    section.add "X-Amz-Target", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600211: Call_DeleteLoggingConfiguration_600199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the <a>LoggingConfiguration</a> from the specified web ACL.
  ## 
  let valid = call_600211.validator(path, query, header, formData, body)
  let scheme = call_600211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600211.url(scheme.get, call_600211.host, call_600211.base,
                         call_600211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600211, url, valid)

proc call*(call_600212: Call_DeleteLoggingConfiguration_600199; body: JsonNode): Recallable =
  ## deleteLoggingConfiguration
  ## Permanently deletes the <a>LoggingConfiguration</a> from the specified web ACL.
  ##   body: JObject (required)
  var body_600213 = newJObject()
  if body != nil:
    body_600213 = body
  result = call_600212.call(nil, nil, nil, nil, body_600213)

var deleteLoggingConfiguration* = Call_DeleteLoggingConfiguration_600199(
    name: "deleteLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteLoggingConfiguration",
    validator: validate_DeleteLoggingConfiguration_600200, base: "/",
    url: url_DeleteLoggingConfiguration_600201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePermissionPolicy_600214 = ref object of OpenApiRestCall_599368
proc url_DeletePermissionPolicy_600216(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePermissionPolicy_600215(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Permanently deletes an IAM policy from the specified RuleGroup.</p> <p>The user making the request must be the owner of the RuleGroup.</p>
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
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600219 = header.getOrDefault("X-Amz-Target")
  valid_600219 = validateParameter(valid_600219, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeletePermissionPolicy"))
  if valid_600219 != nil:
    section.add "X-Amz-Target", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600226: Call_DeletePermissionPolicy_600214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes an IAM policy from the specified RuleGroup.</p> <p>The user making the request must be the owner of the RuleGroup.</p>
  ## 
  let valid = call_600226.validator(path, query, header, formData, body)
  let scheme = call_600226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600226.url(scheme.get, call_600226.host, call_600226.base,
                         call_600226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600226, url, valid)

proc call*(call_600227: Call_DeletePermissionPolicy_600214; body: JsonNode): Recallable =
  ## deletePermissionPolicy
  ## <p>Permanently deletes an IAM policy from the specified RuleGroup.</p> <p>The user making the request must be the owner of the RuleGroup.</p>
  ##   body: JObject (required)
  var body_600228 = newJObject()
  if body != nil:
    body_600228 = body
  result = call_600227.call(nil, nil, nil, nil, body_600228)

var deletePermissionPolicy* = Call_DeletePermissionPolicy_600214(
    name: "deletePermissionPolicy", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeletePermissionPolicy",
    validator: validate_DeletePermissionPolicy_600215, base: "/",
    url: url_DeletePermissionPolicy_600216, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRateBasedRule_600229 = ref object of OpenApiRestCall_599368
proc url_DeleteRateBasedRule_600231(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRateBasedRule_600230(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>RateBasedRule</a>. You can't delete a rule if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a rule from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RateBasedRule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RateBasedRule</code> to remove predicates, if any. For more information, see <a>UpdateRateBasedRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRateBasedRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRateBasedRule</code> request.</p> </li> </ol>
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
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600234 = header.getOrDefault("X-Amz-Target")
  valid_600234 = validateParameter(valid_600234, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRateBasedRule"))
  if valid_600234 != nil:
    section.add "X-Amz-Target", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600241: Call_DeleteRateBasedRule_600229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>RateBasedRule</a>. You can't delete a rule if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a rule from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RateBasedRule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RateBasedRule</code> to remove predicates, if any. For more information, see <a>UpdateRateBasedRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRateBasedRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRateBasedRule</code> request.</p> </li> </ol>
  ## 
  let valid = call_600241.validator(path, query, header, formData, body)
  let scheme = call_600241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600241.url(scheme.get, call_600241.host, call_600241.base,
                         call_600241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600241, url, valid)

proc call*(call_600242: Call_DeleteRateBasedRule_600229; body: JsonNode): Recallable =
  ## deleteRateBasedRule
  ## <p>Permanently deletes a <a>RateBasedRule</a>. You can't delete a rule if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a rule from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RateBasedRule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RateBasedRule</code> to remove predicates, if any. For more information, see <a>UpdateRateBasedRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRateBasedRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRateBasedRule</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600243 = newJObject()
  if body != nil:
    body_600243 = body
  result = call_600242.call(nil, nil, nil, nil, body_600243)

var deleteRateBasedRule* = Call_DeleteRateBasedRule_600229(
    name: "deleteRateBasedRule", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRateBasedRule",
    validator: validate_DeleteRateBasedRule_600230, base: "/",
    url: url_DeleteRateBasedRule_600231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegexMatchSet_600244 = ref object of OpenApiRestCall_599368
proc url_DeleteRegexMatchSet_600246(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRegexMatchSet_600245(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>RegexMatchSet</a>. You can't delete a <code>RegexMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <code>RegexMatchTuples</code> objects (any filters).</p> <p>If you just want to remove a <code>RegexMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>RegexMatchSet</code> to remove filters, if any. For more information, see <a>UpdateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteRegexMatchSet</code> request.</p> </li> </ol>
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
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600249 = header.getOrDefault("X-Amz-Target")
  valid_600249 = validateParameter(valid_600249, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRegexMatchSet"))
  if valid_600249 != nil:
    section.add "X-Amz-Target", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600256: Call_DeleteRegexMatchSet_600244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>RegexMatchSet</a>. You can't delete a <code>RegexMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <code>RegexMatchTuples</code> objects (any filters).</p> <p>If you just want to remove a <code>RegexMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>RegexMatchSet</code> to remove filters, if any. For more information, see <a>UpdateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteRegexMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_600256.validator(path, query, header, formData, body)
  let scheme = call_600256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600256.url(scheme.get, call_600256.host, call_600256.base,
                         call_600256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600256, url, valid)

proc call*(call_600257: Call_DeleteRegexMatchSet_600244; body: JsonNode): Recallable =
  ## deleteRegexMatchSet
  ## <p>Permanently deletes a <a>RegexMatchSet</a>. You can't delete a <code>RegexMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <code>RegexMatchTuples</code> objects (any filters).</p> <p>If you just want to remove a <code>RegexMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>RegexMatchSet</code> to remove filters, if any. For more information, see <a>UpdateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteRegexMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600258 = newJObject()
  if body != nil:
    body_600258 = body
  result = call_600257.call(nil, nil, nil, nil, body_600258)

var deleteRegexMatchSet* = Call_DeleteRegexMatchSet_600244(
    name: "deleteRegexMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRegexMatchSet",
    validator: validate_DeleteRegexMatchSet_600245, base: "/",
    url: url_DeleteRegexMatchSet_600246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegexPatternSet_600259 = ref object of OpenApiRestCall_599368
proc url_DeleteRegexPatternSet_600261(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRegexPatternSet_600260(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Permanently deletes a <a>RegexPatternSet</a>. You can't delete a <code>RegexPatternSet</code> if it's still used in any <code>RegexMatchSet</code> or if the <code>RegexPatternSet</code> is not empty. 
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
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600264 = header.getOrDefault("X-Amz-Target")
  valid_600264 = validateParameter(valid_600264, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRegexPatternSet"))
  if valid_600264 != nil:
    section.add "X-Amz-Target", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Content-Sha256", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Algorithm")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Algorithm", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Signature")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Signature", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-SignedHeaders", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Credential")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Credential", valid_600269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600271: Call_DeleteRegexPatternSet_600259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a <a>RegexPatternSet</a>. You can't delete a <code>RegexPatternSet</code> if it's still used in any <code>RegexMatchSet</code> or if the <code>RegexPatternSet</code> is not empty. 
  ## 
  let valid = call_600271.validator(path, query, header, formData, body)
  let scheme = call_600271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600271.url(scheme.get, call_600271.host, call_600271.base,
                         call_600271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600271, url, valid)

proc call*(call_600272: Call_DeleteRegexPatternSet_600259; body: JsonNode): Recallable =
  ## deleteRegexPatternSet
  ## Permanently deletes a <a>RegexPatternSet</a>. You can't delete a <code>RegexPatternSet</code> if it's still used in any <code>RegexMatchSet</code> or if the <code>RegexPatternSet</code> is not empty. 
  ##   body: JObject (required)
  var body_600273 = newJObject()
  if body != nil:
    body_600273 = body
  result = call_600272.call(nil, nil, nil, nil, body_600273)

var deleteRegexPatternSet* = Call_DeleteRegexPatternSet_600259(
    name: "deleteRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRegexPatternSet",
    validator: validate_DeleteRegexPatternSet_600260, base: "/",
    url: url_DeleteRegexPatternSet_600261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRule_600274 = ref object of OpenApiRestCall_599368
proc url_DeleteRule_600276(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRule_600275(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>Rule</a>. You can't delete a <code>Rule</code> if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a <code>Rule</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>Rule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>Rule</code> to remove predicates, if any. For more information, see <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRule</code> request.</p> </li> </ol>
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
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600279 = header.getOrDefault("X-Amz-Target")
  valid_600279 = validateParameter(valid_600279, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRule"))
  if valid_600279 != nil:
    section.add "X-Amz-Target", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_DeleteRule_600274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>Rule</a>. You can't delete a <code>Rule</code> if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a <code>Rule</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>Rule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>Rule</code> to remove predicates, if any. For more information, see <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRule</code> request.</p> </li> </ol>
  ## 
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_DeleteRule_600274; body: JsonNode): Recallable =
  ## deleteRule
  ## <p>Permanently deletes a <a>Rule</a>. You can't delete a <code>Rule</code> if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a <code>Rule</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>Rule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>Rule</code> to remove predicates, if any. For more information, see <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRule</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600288 = newJObject()
  if body != nil:
    body_600288 = body
  result = call_600287.call(nil, nil, nil, nil, body_600288)

var deleteRule* = Call_DeleteRule_600274(name: "deleteRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRule",
                                      validator: validate_DeleteRule_600275,
                                      base: "/", url: url_DeleteRule_600276,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRuleGroup_600289 = ref object of OpenApiRestCall_599368
proc url_DeleteRuleGroup_600291(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRuleGroup_600290(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>RuleGroup</a>. You can't delete a <code>RuleGroup</code> if it's still used in any <code>WebACL</code> objects or if it still includes any rules.</p> <p>If you just want to remove a <code>RuleGroup</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RuleGroup</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RuleGroup</code> to remove rules, if any. For more information, see <a>UpdateRuleGroup</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRuleGroup</code> request.</p> </li> <li> <p>Submit a <code>DeleteRuleGroup</code> request.</p> </li> </ol>
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
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600294 = header.getOrDefault("X-Amz-Target")
  valid_600294 = validateParameter(valid_600294, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRuleGroup"))
  if valid_600294 != nil:
    section.add "X-Amz-Target", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600301: Call_DeleteRuleGroup_600289; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>RuleGroup</a>. You can't delete a <code>RuleGroup</code> if it's still used in any <code>WebACL</code> objects or if it still includes any rules.</p> <p>If you just want to remove a <code>RuleGroup</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RuleGroup</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RuleGroup</code> to remove rules, if any. For more information, see <a>UpdateRuleGroup</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRuleGroup</code> request.</p> </li> <li> <p>Submit a <code>DeleteRuleGroup</code> request.</p> </li> </ol>
  ## 
  let valid = call_600301.validator(path, query, header, formData, body)
  let scheme = call_600301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600301.url(scheme.get, call_600301.host, call_600301.base,
                         call_600301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600301, url, valid)

proc call*(call_600302: Call_DeleteRuleGroup_600289; body: JsonNode): Recallable =
  ## deleteRuleGroup
  ## <p>Permanently deletes a <a>RuleGroup</a>. You can't delete a <code>RuleGroup</code> if it's still used in any <code>WebACL</code> objects or if it still includes any rules.</p> <p>If you just want to remove a <code>RuleGroup</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RuleGroup</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RuleGroup</code> to remove rules, if any. For more information, see <a>UpdateRuleGroup</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRuleGroup</code> request.</p> </li> <li> <p>Submit a <code>DeleteRuleGroup</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600303 = newJObject()
  if body != nil:
    body_600303 = body
  result = call_600302.call(nil, nil, nil, nil, body_600303)

var deleteRuleGroup* = Call_DeleteRuleGroup_600289(name: "deleteRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRuleGroup",
    validator: validate_DeleteRuleGroup_600290, base: "/", url: url_DeleteRuleGroup_600291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSizeConstraintSet_600304 = ref object of OpenApiRestCall_599368
proc url_DeleteSizeConstraintSet_600306(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSizeConstraintSet_600305(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>SizeConstraintSet</a>. You can't delete a <code>SizeConstraintSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>SizeConstraint</a> objects (any filters).</p> <p>If you just want to remove a <code>SizeConstraintSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>SizeConstraintSet</code> to remove filters, if any. For more information, see <a>UpdateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSizeConstraintSet</code> request.</p> </li> </ol>
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
  var valid_600307 = header.getOrDefault("X-Amz-Date")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Date", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Security-Token")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Security-Token", valid_600308
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600309 = header.getOrDefault("X-Amz-Target")
  valid_600309 = validateParameter(valid_600309, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteSizeConstraintSet"))
  if valid_600309 != nil:
    section.add "X-Amz-Target", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_DeleteSizeConstraintSet_600304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>SizeConstraintSet</a>. You can't delete a <code>SizeConstraintSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>SizeConstraint</a> objects (any filters).</p> <p>If you just want to remove a <code>SizeConstraintSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>SizeConstraintSet</code> to remove filters, if any. For more information, see <a>UpdateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSizeConstraintSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_DeleteSizeConstraintSet_600304; body: JsonNode): Recallable =
  ## deleteSizeConstraintSet
  ## <p>Permanently deletes a <a>SizeConstraintSet</a>. You can't delete a <code>SizeConstraintSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>SizeConstraint</a> objects (any filters).</p> <p>If you just want to remove a <code>SizeConstraintSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>SizeConstraintSet</code> to remove filters, if any. For more information, see <a>UpdateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSizeConstraintSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600318 = newJObject()
  if body != nil:
    body_600318 = body
  result = call_600317.call(nil, nil, nil, nil, body_600318)

var deleteSizeConstraintSet* = Call_DeleteSizeConstraintSet_600304(
    name: "deleteSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteSizeConstraintSet",
    validator: validate_DeleteSizeConstraintSet_600305, base: "/",
    url: url_DeleteSizeConstraintSet_600306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSqlInjectionMatchSet_600319 = ref object of OpenApiRestCall_599368
proc url_DeleteSqlInjectionMatchSet_600321(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSqlInjectionMatchSet_600320(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>SqlInjectionMatchSet</a>. You can't delete a <code>SqlInjectionMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>SqlInjectionMatchTuple</a> objects.</p> <p>If you just want to remove a <code>SqlInjectionMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SqlInjectionMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>SqlInjectionMatchSet</code> to remove filters, if any. For more information, see <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> </ol>
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
  var valid_600322 = header.getOrDefault("X-Amz-Date")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Date", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Security-Token")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Security-Token", valid_600323
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600324 = header.getOrDefault("X-Amz-Target")
  valid_600324 = validateParameter(valid_600324, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteSqlInjectionMatchSet"))
  if valid_600324 != nil:
    section.add "X-Amz-Target", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Content-Sha256", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Algorithm")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Algorithm", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Signature")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Signature", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-SignedHeaders", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Credential")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Credential", valid_600329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600331: Call_DeleteSqlInjectionMatchSet_600319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>SqlInjectionMatchSet</a>. You can't delete a <code>SqlInjectionMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>SqlInjectionMatchTuple</a> objects.</p> <p>If you just want to remove a <code>SqlInjectionMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SqlInjectionMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>SqlInjectionMatchSet</code> to remove filters, if any. For more information, see <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_600331.validator(path, query, header, formData, body)
  let scheme = call_600331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600331.url(scheme.get, call_600331.host, call_600331.base,
                         call_600331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600331, url, valid)

proc call*(call_600332: Call_DeleteSqlInjectionMatchSet_600319; body: JsonNode): Recallable =
  ## deleteSqlInjectionMatchSet
  ## <p>Permanently deletes a <a>SqlInjectionMatchSet</a>. You can't delete a <code>SqlInjectionMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>SqlInjectionMatchTuple</a> objects.</p> <p>If you just want to remove a <code>SqlInjectionMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SqlInjectionMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>SqlInjectionMatchSet</code> to remove filters, if any. For more information, see <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600333 = newJObject()
  if body != nil:
    body_600333 = body
  result = call_600332.call(nil, nil, nil, nil, body_600333)

var deleteSqlInjectionMatchSet* = Call_DeleteSqlInjectionMatchSet_600319(
    name: "deleteSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteSqlInjectionMatchSet",
    validator: validate_DeleteSqlInjectionMatchSet_600320, base: "/",
    url: url_DeleteSqlInjectionMatchSet_600321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebACL_600334 = ref object of OpenApiRestCall_599368
proc url_DeleteWebACL_600336(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteWebACL_600335(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Permanently deletes a <a>WebACL</a>. You can't delete a <code>WebACL</code> if it still contains any <code>Rules</code>.</p> <p>To delete a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>WebACL</code> to remove <code>Rules</code>, if any. For more information, see <a>UpdateWebACL</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteWebACL</code> request.</p> </li> <li> <p>Submit a <code>DeleteWebACL</code> request.</p> </li> </ol>
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
  var valid_600337 = header.getOrDefault("X-Amz-Date")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Date", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Security-Token")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Security-Token", valid_600338
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600339 = header.getOrDefault("X-Amz-Target")
  valid_600339 = validateParameter(valid_600339, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteWebACL"))
  if valid_600339 != nil:
    section.add "X-Amz-Target", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Content-Sha256", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Algorithm")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Algorithm", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Signature")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Signature", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-SignedHeaders", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Credential")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Credential", valid_600344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600346: Call_DeleteWebACL_600334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>WebACL</a>. You can't delete a <code>WebACL</code> if it still contains any <code>Rules</code>.</p> <p>To delete a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>WebACL</code> to remove <code>Rules</code>, if any. For more information, see <a>UpdateWebACL</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteWebACL</code> request.</p> </li> <li> <p>Submit a <code>DeleteWebACL</code> request.</p> </li> </ol>
  ## 
  let valid = call_600346.validator(path, query, header, formData, body)
  let scheme = call_600346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600346.url(scheme.get, call_600346.host, call_600346.base,
                         call_600346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600346, url, valid)

proc call*(call_600347: Call_DeleteWebACL_600334; body: JsonNode): Recallable =
  ## deleteWebACL
  ## <p>Permanently deletes a <a>WebACL</a>. You can't delete a <code>WebACL</code> if it still contains any <code>Rules</code>.</p> <p>To delete a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>WebACL</code> to remove <code>Rules</code>, if any. For more information, see <a>UpdateWebACL</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteWebACL</code> request.</p> </li> <li> <p>Submit a <code>DeleteWebACL</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600348 = newJObject()
  if body != nil:
    body_600348 = body
  result = call_600347.call(nil, nil, nil, nil, body_600348)

var deleteWebACL* = Call_DeleteWebACL_600334(name: "deleteWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteWebACL",
    validator: validate_DeleteWebACL_600335, base: "/", url: url_DeleteWebACL_600336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteXssMatchSet_600349 = ref object of OpenApiRestCall_599368
proc url_DeleteXssMatchSet_600351(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteXssMatchSet_600350(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Permanently deletes an <a>XssMatchSet</a>. You can't delete an <code>XssMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>XssMatchTuple</a> objects.</p> <p>If you just want to remove an <code>XssMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>XssMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>XssMatchSet</code> to remove filters, if any. For more information, see <a>UpdateXssMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteXssMatchSet</code> request.</p> </li> </ol>
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
  var valid_600352 = header.getOrDefault("X-Amz-Date")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Date", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Security-Token")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Security-Token", valid_600353
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600354 = header.getOrDefault("X-Amz-Target")
  valid_600354 = validateParameter(valid_600354, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteXssMatchSet"))
  if valid_600354 != nil:
    section.add "X-Amz-Target", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Content-Sha256", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Algorithm")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Algorithm", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Signature")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Signature", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-SignedHeaders", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Credential")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Credential", valid_600359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600361: Call_DeleteXssMatchSet_600349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes an <a>XssMatchSet</a>. You can't delete an <code>XssMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>XssMatchTuple</a> objects.</p> <p>If you just want to remove an <code>XssMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>XssMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>XssMatchSet</code> to remove filters, if any. For more information, see <a>UpdateXssMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteXssMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_600361.validator(path, query, header, formData, body)
  let scheme = call_600361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600361.url(scheme.get, call_600361.host, call_600361.base,
                         call_600361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600361, url, valid)

proc call*(call_600362: Call_DeleteXssMatchSet_600349; body: JsonNode): Recallable =
  ## deleteXssMatchSet
  ## <p>Permanently deletes an <a>XssMatchSet</a>. You can't delete an <code>XssMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>XssMatchTuple</a> objects.</p> <p>If you just want to remove an <code>XssMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>XssMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>XssMatchSet</code> to remove filters, if any. For more information, see <a>UpdateXssMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteXssMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_600363 = newJObject()
  if body != nil:
    body_600363 = body
  result = call_600362.call(nil, nil, nil, nil, body_600363)

var deleteXssMatchSet* = Call_DeleteXssMatchSet_600349(name: "deleteXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteXssMatchSet",
    validator: validate_DeleteXssMatchSet_600350, base: "/",
    url: url_DeleteXssMatchSet_600351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebACL_600364 = ref object of OpenApiRestCall_599368
proc url_DisassociateWebACL_600366(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DisassociateWebACL_600365(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Removes a web ACL from the specified resource, either an application load balancer or Amazon API Gateway stage.
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
  var valid_600367 = header.getOrDefault("X-Amz-Date")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Date", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Security-Token")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Security-Token", valid_600368
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600369 = header.getOrDefault("X-Amz-Target")
  valid_600369 = validateParameter(valid_600369, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DisassociateWebACL"))
  if valid_600369 != nil:
    section.add "X-Amz-Target", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Content-Sha256", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Algorithm")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Algorithm", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Signature")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Signature", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-SignedHeaders", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Credential")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Credential", valid_600374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_DisassociateWebACL_600364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a web ACL from the specified resource, either an application load balancer or Amazon API Gateway stage.
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_DisassociateWebACL_600364; body: JsonNode): Recallable =
  ## disassociateWebACL
  ## Removes a web ACL from the specified resource, either an application load balancer or Amazon API Gateway stage.
  ##   body: JObject (required)
  var body_600378 = newJObject()
  if body != nil:
    body_600378 = body
  result = call_600377.call(nil, nil, nil, nil, body_600378)

var disassociateWebACL* = Call_DisassociateWebACL_600364(
    name: "disassociateWebACL", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DisassociateWebACL",
    validator: validate_DisassociateWebACL_600365, base: "/",
    url: url_DisassociateWebACL_600366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetByteMatchSet_600379 = ref object of OpenApiRestCall_599368
proc url_GetByteMatchSet_600381(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetByteMatchSet_600380(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns the <a>ByteMatchSet</a> specified by <code>ByteMatchSetId</code>.
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
  var valid_600382 = header.getOrDefault("X-Amz-Date")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Date", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Security-Token")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Security-Token", valid_600383
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600384 = header.getOrDefault("X-Amz-Target")
  valid_600384 = validateParameter(valid_600384, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetByteMatchSet"))
  if valid_600384 != nil:
    section.add "X-Amz-Target", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Content-Sha256", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Algorithm")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Algorithm", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Signature")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Signature", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-SignedHeaders", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Credential")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Credential", valid_600389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600391: Call_GetByteMatchSet_600379; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>ByteMatchSet</a> specified by <code>ByteMatchSetId</code>.
  ## 
  let valid = call_600391.validator(path, query, header, formData, body)
  let scheme = call_600391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600391.url(scheme.get, call_600391.host, call_600391.base,
                         call_600391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600391, url, valid)

proc call*(call_600392: Call_GetByteMatchSet_600379; body: JsonNode): Recallable =
  ## getByteMatchSet
  ## Returns the <a>ByteMatchSet</a> specified by <code>ByteMatchSetId</code>.
  ##   body: JObject (required)
  var body_600393 = newJObject()
  if body != nil:
    body_600393 = body
  result = call_600392.call(nil, nil, nil, nil, body_600393)

var getByteMatchSet* = Call_GetByteMatchSet_600379(name: "getByteMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetByteMatchSet",
    validator: validate_GetByteMatchSet_600380, base: "/", url: url_GetByteMatchSet_600381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeToken_600394 = ref object of OpenApiRestCall_599368
proc url_GetChangeToken_600396(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetChangeToken_600395(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>When you want to create, update, or delete AWS WAF objects, get a change token and include the change token in the create, update, or delete request. Change tokens ensure that your application doesn't submit conflicting requests to AWS WAF.</p> <p>Each create, update, or delete request must use a unique change token. If your application submits a <code>GetChangeToken</code> request and then submits a second <code>GetChangeToken</code> request before submitting a create, update, or delete request, the second <code>GetChangeToken</code> request returns the same value as the first <code>GetChangeToken</code> request.</p> <p>When you use a change token in a create, update, or delete request, the status of the change token changes to <code>PENDING</code>, which indicates that AWS WAF is propagating the change to all AWS WAF servers. Use <code>GetChangeTokenStatus</code> to determine the status of your change token.</p>
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
  var valid_600397 = header.getOrDefault("X-Amz-Date")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Date", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Security-Token")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Security-Token", valid_600398
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600399 = header.getOrDefault("X-Amz-Target")
  valid_600399 = validateParameter(valid_600399, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetChangeToken"))
  if valid_600399 != nil:
    section.add "X-Amz-Target", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Content-Sha256", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Algorithm")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Algorithm", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Signature")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Signature", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-SignedHeaders", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Credential")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Credential", valid_600404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600406: Call_GetChangeToken_600394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>When you want to create, update, or delete AWS WAF objects, get a change token and include the change token in the create, update, or delete request. Change tokens ensure that your application doesn't submit conflicting requests to AWS WAF.</p> <p>Each create, update, or delete request must use a unique change token. If your application submits a <code>GetChangeToken</code> request and then submits a second <code>GetChangeToken</code> request before submitting a create, update, or delete request, the second <code>GetChangeToken</code> request returns the same value as the first <code>GetChangeToken</code> request.</p> <p>When you use a change token in a create, update, or delete request, the status of the change token changes to <code>PENDING</code>, which indicates that AWS WAF is propagating the change to all AWS WAF servers. Use <code>GetChangeTokenStatus</code> to determine the status of your change token.</p>
  ## 
  let valid = call_600406.validator(path, query, header, formData, body)
  let scheme = call_600406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600406.url(scheme.get, call_600406.host, call_600406.base,
                         call_600406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600406, url, valid)

proc call*(call_600407: Call_GetChangeToken_600394; body: JsonNode): Recallable =
  ## getChangeToken
  ## <p>When you want to create, update, or delete AWS WAF objects, get a change token and include the change token in the create, update, or delete request. Change tokens ensure that your application doesn't submit conflicting requests to AWS WAF.</p> <p>Each create, update, or delete request must use a unique change token. If your application submits a <code>GetChangeToken</code> request and then submits a second <code>GetChangeToken</code> request before submitting a create, update, or delete request, the second <code>GetChangeToken</code> request returns the same value as the first <code>GetChangeToken</code> request.</p> <p>When you use a change token in a create, update, or delete request, the status of the change token changes to <code>PENDING</code>, which indicates that AWS WAF is propagating the change to all AWS WAF servers. Use <code>GetChangeTokenStatus</code> to determine the status of your change token.</p>
  ##   body: JObject (required)
  var body_600408 = newJObject()
  if body != nil:
    body_600408 = body
  result = call_600407.call(nil, nil, nil, nil, body_600408)

var getChangeToken* = Call_GetChangeToken_600394(name: "getChangeToken",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetChangeToken",
    validator: validate_GetChangeToken_600395, base: "/", url: url_GetChangeToken_600396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeTokenStatus_600409 = ref object of OpenApiRestCall_599368
proc url_GetChangeTokenStatus_600411(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetChangeTokenStatus_600410(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the status of a <code>ChangeToken</code> that you got by calling <a>GetChangeToken</a>. <code>ChangeTokenStatus</code> is one of the following values:</p> <ul> <li> <p> <code>PROVISIONED</code>: You requested the change token by calling <code>GetChangeToken</code>, but you haven't used it yet in a call to create, update, or delete an AWS WAF object.</p> </li> <li> <p> <code>PENDING</code>: AWS WAF is propagating the create, update, or delete request to all AWS WAF servers.</p> </li> <li> <p> <code>INSYNC</code>: Propagation is complete.</p> </li> </ul>
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
  var valid_600412 = header.getOrDefault("X-Amz-Date")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Date", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Security-Token")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Security-Token", valid_600413
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600414 = header.getOrDefault("X-Amz-Target")
  valid_600414 = validateParameter(valid_600414, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetChangeTokenStatus"))
  if valid_600414 != nil:
    section.add "X-Amz-Target", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Content-Sha256", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Algorithm")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Algorithm", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Signature")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Signature", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-SignedHeaders", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Credential")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Credential", valid_600419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600421: Call_GetChangeTokenStatus_600409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the status of a <code>ChangeToken</code> that you got by calling <a>GetChangeToken</a>. <code>ChangeTokenStatus</code> is one of the following values:</p> <ul> <li> <p> <code>PROVISIONED</code>: You requested the change token by calling <code>GetChangeToken</code>, but you haven't used it yet in a call to create, update, or delete an AWS WAF object.</p> </li> <li> <p> <code>PENDING</code>: AWS WAF is propagating the create, update, or delete request to all AWS WAF servers.</p> </li> <li> <p> <code>INSYNC</code>: Propagation is complete.</p> </li> </ul>
  ## 
  let valid = call_600421.validator(path, query, header, formData, body)
  let scheme = call_600421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600421.url(scheme.get, call_600421.host, call_600421.base,
                         call_600421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600421, url, valid)

proc call*(call_600422: Call_GetChangeTokenStatus_600409; body: JsonNode): Recallable =
  ## getChangeTokenStatus
  ## <p>Returns the status of a <code>ChangeToken</code> that you got by calling <a>GetChangeToken</a>. <code>ChangeTokenStatus</code> is one of the following values:</p> <ul> <li> <p> <code>PROVISIONED</code>: You requested the change token by calling <code>GetChangeToken</code>, but you haven't used it yet in a call to create, update, or delete an AWS WAF object.</p> </li> <li> <p> <code>PENDING</code>: AWS WAF is propagating the create, update, or delete request to all AWS WAF servers.</p> </li> <li> <p> <code>INSYNC</code>: Propagation is complete.</p> </li> </ul>
  ##   body: JObject (required)
  var body_600423 = newJObject()
  if body != nil:
    body_600423 = body
  result = call_600422.call(nil, nil, nil, nil, body_600423)

var getChangeTokenStatus* = Call_GetChangeTokenStatus_600409(
    name: "getChangeTokenStatus", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetChangeTokenStatus",
    validator: validate_GetChangeTokenStatus_600410, base: "/",
    url: url_GetChangeTokenStatus_600411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGeoMatchSet_600424 = ref object of OpenApiRestCall_599368
proc url_GetGeoMatchSet_600426(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGeoMatchSet_600425(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns the <a>GeoMatchSet</a> that is specified by <code>GeoMatchSetId</code>.
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
  var valid_600427 = header.getOrDefault("X-Amz-Date")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Date", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Security-Token")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Security-Token", valid_600428
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600429 = header.getOrDefault("X-Amz-Target")
  valid_600429 = validateParameter(valid_600429, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetGeoMatchSet"))
  if valid_600429 != nil:
    section.add "X-Amz-Target", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Content-Sha256", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Algorithm")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Algorithm", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Signature")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Signature", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-SignedHeaders", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Credential")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Credential", valid_600434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600436: Call_GetGeoMatchSet_600424; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>GeoMatchSet</a> that is specified by <code>GeoMatchSetId</code>.
  ## 
  let valid = call_600436.validator(path, query, header, formData, body)
  let scheme = call_600436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600436.url(scheme.get, call_600436.host, call_600436.base,
                         call_600436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600436, url, valid)

proc call*(call_600437: Call_GetGeoMatchSet_600424; body: JsonNode): Recallable =
  ## getGeoMatchSet
  ## Returns the <a>GeoMatchSet</a> that is specified by <code>GeoMatchSetId</code>.
  ##   body: JObject (required)
  var body_600438 = newJObject()
  if body != nil:
    body_600438 = body
  result = call_600437.call(nil, nil, nil, nil, body_600438)

var getGeoMatchSet* = Call_GetGeoMatchSet_600424(name: "getGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetGeoMatchSet",
    validator: validate_GetGeoMatchSet_600425, base: "/", url: url_GetGeoMatchSet_600426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_600439 = ref object of OpenApiRestCall_599368
proc url_GetIPSet_600441(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIPSet_600440(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a>IPSet</a> that is specified by <code>IPSetId</code>.
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
  var valid_600442 = header.getOrDefault("X-Amz-Date")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Date", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Security-Token")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Security-Token", valid_600443
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600444 = header.getOrDefault("X-Amz-Target")
  valid_600444 = validateParameter(valid_600444, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetIPSet"))
  if valid_600444 != nil:
    section.add "X-Amz-Target", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-Content-Sha256", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Algorithm")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Algorithm", valid_600446
  var valid_600447 = header.getOrDefault("X-Amz-Signature")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "X-Amz-Signature", valid_600447
  var valid_600448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-SignedHeaders", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Credential")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Credential", valid_600449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600451: Call_GetIPSet_600439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>IPSet</a> that is specified by <code>IPSetId</code>.
  ## 
  let valid = call_600451.validator(path, query, header, formData, body)
  let scheme = call_600451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600451.url(scheme.get, call_600451.host, call_600451.base,
                         call_600451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600451, url, valid)

proc call*(call_600452: Call_GetIPSet_600439; body: JsonNode): Recallable =
  ## getIPSet
  ## Returns the <a>IPSet</a> that is specified by <code>IPSetId</code>.
  ##   body: JObject (required)
  var body_600453 = newJObject()
  if body != nil:
    body_600453 = body
  result = call_600452.call(nil, nil, nil, nil, body_600453)

var getIPSet* = Call_GetIPSet_600439(name: "getIPSet", meth: HttpMethod.HttpPost,
                                  host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetIPSet",
                                  validator: validate_GetIPSet_600440, base: "/",
                                  url: url_GetIPSet_600441,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggingConfiguration_600454 = ref object of OpenApiRestCall_599368
proc url_GetLoggingConfiguration_600456(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLoggingConfiguration_600455(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a>LoggingConfiguration</a> for the specified web ACL.
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
  var valid_600457 = header.getOrDefault("X-Amz-Date")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Date", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Security-Token")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Security-Token", valid_600458
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600459 = header.getOrDefault("X-Amz-Target")
  valid_600459 = validateParameter(valid_600459, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetLoggingConfiguration"))
  if valid_600459 != nil:
    section.add "X-Amz-Target", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Content-Sha256", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Algorithm")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Algorithm", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Signature")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Signature", valid_600462
  var valid_600463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600463 = validateParameter(valid_600463, JString, required = false,
                                 default = nil)
  if valid_600463 != nil:
    section.add "X-Amz-SignedHeaders", valid_600463
  var valid_600464 = header.getOrDefault("X-Amz-Credential")
  valid_600464 = validateParameter(valid_600464, JString, required = false,
                                 default = nil)
  if valid_600464 != nil:
    section.add "X-Amz-Credential", valid_600464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600466: Call_GetLoggingConfiguration_600454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>LoggingConfiguration</a> for the specified web ACL.
  ## 
  let valid = call_600466.validator(path, query, header, formData, body)
  let scheme = call_600466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600466.url(scheme.get, call_600466.host, call_600466.base,
                         call_600466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600466, url, valid)

proc call*(call_600467: Call_GetLoggingConfiguration_600454; body: JsonNode): Recallable =
  ## getLoggingConfiguration
  ## Returns the <a>LoggingConfiguration</a> for the specified web ACL.
  ##   body: JObject (required)
  var body_600468 = newJObject()
  if body != nil:
    body_600468 = body
  result = call_600467.call(nil, nil, nil, nil, body_600468)

var getLoggingConfiguration* = Call_GetLoggingConfiguration_600454(
    name: "getLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetLoggingConfiguration",
    validator: validate_GetLoggingConfiguration_600455, base: "/",
    url: url_GetLoggingConfiguration_600456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPermissionPolicy_600469 = ref object of OpenApiRestCall_599368
proc url_GetPermissionPolicy_600471(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPermissionPolicy_600470(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns the IAM policy attached to the RuleGroup.
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
  var valid_600472 = header.getOrDefault("X-Amz-Date")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Date", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Security-Token")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Security-Token", valid_600473
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600474 = header.getOrDefault("X-Amz-Target")
  valid_600474 = validateParameter(valid_600474, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetPermissionPolicy"))
  if valid_600474 != nil:
    section.add "X-Amz-Target", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Content-Sha256", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Algorithm")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Algorithm", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Signature")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Signature", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-SignedHeaders", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Credential")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Credential", valid_600479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600481: Call_GetPermissionPolicy_600469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the IAM policy attached to the RuleGroup.
  ## 
  let valid = call_600481.validator(path, query, header, formData, body)
  let scheme = call_600481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600481.url(scheme.get, call_600481.host, call_600481.base,
                         call_600481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600481, url, valid)

proc call*(call_600482: Call_GetPermissionPolicy_600469; body: JsonNode): Recallable =
  ## getPermissionPolicy
  ## Returns the IAM policy attached to the RuleGroup.
  ##   body: JObject (required)
  var body_600483 = newJObject()
  if body != nil:
    body_600483 = body
  result = call_600482.call(nil, nil, nil, nil, body_600483)

var getPermissionPolicy* = Call_GetPermissionPolicy_600469(
    name: "getPermissionPolicy", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetPermissionPolicy",
    validator: validate_GetPermissionPolicy_600470, base: "/",
    url: url_GetPermissionPolicy_600471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRateBasedRule_600484 = ref object of OpenApiRestCall_599368
proc url_GetRateBasedRule_600486(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRateBasedRule_600485(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the <a>RateBasedRule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRateBasedRule</code> request.
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
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600489 = header.getOrDefault("X-Amz-Target")
  valid_600489 = validateParameter(valid_600489, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRateBasedRule"))
  if valid_600489 != nil:
    section.add "X-Amz-Target", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Content-Sha256", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Algorithm")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Algorithm", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Signature")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Signature", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-SignedHeaders", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Credential")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Credential", valid_600494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600496: Call_GetRateBasedRule_600484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>RateBasedRule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRateBasedRule</code> request.
  ## 
  let valid = call_600496.validator(path, query, header, formData, body)
  let scheme = call_600496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600496.url(scheme.get, call_600496.host, call_600496.base,
                         call_600496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600496, url, valid)

proc call*(call_600497: Call_GetRateBasedRule_600484; body: JsonNode): Recallable =
  ## getRateBasedRule
  ## Returns the <a>RateBasedRule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRateBasedRule</code> request.
  ##   body: JObject (required)
  var body_600498 = newJObject()
  if body != nil:
    body_600498 = body
  result = call_600497.call(nil, nil, nil, nil, body_600498)

var getRateBasedRule* = Call_GetRateBasedRule_600484(name: "getRateBasedRule",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRateBasedRule",
    validator: validate_GetRateBasedRule_600485, base: "/",
    url: url_GetRateBasedRule_600486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRateBasedRuleManagedKeys_600499 = ref object of OpenApiRestCall_599368
proc url_GetRateBasedRuleManagedKeys_600501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRateBasedRuleManagedKeys_600500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of IP addresses currently being blocked by the <a>RateBasedRule</a> that is specified by the <code>RuleId</code>. The maximum number of managed keys that will be blocked is 10,000. If more than 10,000 addresses exceed the rate limit, the 10,000 addresses with the highest rates will be blocked.
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
  var valid_600502 = header.getOrDefault("X-Amz-Date")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Date", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Security-Token")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Security-Token", valid_600503
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600504 = header.getOrDefault("X-Amz-Target")
  valid_600504 = validateParameter(valid_600504, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRateBasedRuleManagedKeys"))
  if valid_600504 != nil:
    section.add "X-Amz-Target", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Content-Sha256", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Algorithm")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Algorithm", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Signature")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Signature", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-SignedHeaders", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Credential")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Credential", valid_600509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600511: Call_GetRateBasedRuleManagedKeys_600499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of IP addresses currently being blocked by the <a>RateBasedRule</a> that is specified by the <code>RuleId</code>. The maximum number of managed keys that will be blocked is 10,000. If more than 10,000 addresses exceed the rate limit, the 10,000 addresses with the highest rates will be blocked.
  ## 
  let valid = call_600511.validator(path, query, header, formData, body)
  let scheme = call_600511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600511.url(scheme.get, call_600511.host, call_600511.base,
                         call_600511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600511, url, valid)

proc call*(call_600512: Call_GetRateBasedRuleManagedKeys_600499; body: JsonNode): Recallable =
  ## getRateBasedRuleManagedKeys
  ## Returns an array of IP addresses currently being blocked by the <a>RateBasedRule</a> that is specified by the <code>RuleId</code>. The maximum number of managed keys that will be blocked is 10,000. If more than 10,000 addresses exceed the rate limit, the 10,000 addresses with the highest rates will be blocked.
  ##   body: JObject (required)
  var body_600513 = newJObject()
  if body != nil:
    body_600513 = body
  result = call_600512.call(nil, nil, nil, nil, body_600513)

var getRateBasedRuleManagedKeys* = Call_GetRateBasedRuleManagedKeys_600499(
    name: "getRateBasedRuleManagedKeys", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRateBasedRuleManagedKeys",
    validator: validate_GetRateBasedRuleManagedKeys_600500, base: "/",
    url: url_GetRateBasedRuleManagedKeys_600501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegexMatchSet_600514 = ref object of OpenApiRestCall_599368
proc url_GetRegexMatchSet_600516(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegexMatchSet_600515(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns the <a>RegexMatchSet</a> specified by <code>RegexMatchSetId</code>.
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
  var valid_600517 = header.getOrDefault("X-Amz-Date")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Date", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-Security-Token")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-Security-Token", valid_600518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600519 = header.getOrDefault("X-Amz-Target")
  valid_600519 = validateParameter(valid_600519, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRegexMatchSet"))
  if valid_600519 != nil:
    section.add "X-Amz-Target", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Content-Sha256", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Algorithm")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Algorithm", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Signature")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Signature", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-SignedHeaders", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Credential")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Credential", valid_600524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_GetRegexMatchSet_600514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>RegexMatchSet</a> specified by <code>RegexMatchSetId</code>.
  ## 
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_GetRegexMatchSet_600514; body: JsonNode): Recallable =
  ## getRegexMatchSet
  ## Returns the <a>RegexMatchSet</a> specified by <code>RegexMatchSetId</code>.
  ##   body: JObject (required)
  var body_600528 = newJObject()
  if body != nil:
    body_600528 = body
  result = call_600527.call(nil, nil, nil, nil, body_600528)

var getRegexMatchSet* = Call_GetRegexMatchSet_600514(name: "getRegexMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRegexMatchSet",
    validator: validate_GetRegexMatchSet_600515, base: "/",
    url: url_GetRegexMatchSet_600516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegexPatternSet_600529 = ref object of OpenApiRestCall_599368
proc url_GetRegexPatternSet_600531(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRegexPatternSet_600530(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns the <a>RegexPatternSet</a> specified by <code>RegexPatternSetId</code>.
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
  var valid_600532 = header.getOrDefault("X-Amz-Date")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "X-Amz-Date", valid_600532
  var valid_600533 = header.getOrDefault("X-Amz-Security-Token")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "X-Amz-Security-Token", valid_600533
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600534 = header.getOrDefault("X-Amz-Target")
  valid_600534 = validateParameter(valid_600534, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRegexPatternSet"))
  if valid_600534 != nil:
    section.add "X-Amz-Target", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Content-Sha256", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Algorithm")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Algorithm", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Signature")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Signature", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-SignedHeaders", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Credential")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Credential", valid_600539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600541: Call_GetRegexPatternSet_600529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>RegexPatternSet</a> specified by <code>RegexPatternSetId</code>.
  ## 
  let valid = call_600541.validator(path, query, header, formData, body)
  let scheme = call_600541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600541.url(scheme.get, call_600541.host, call_600541.base,
                         call_600541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600541, url, valid)

proc call*(call_600542: Call_GetRegexPatternSet_600529; body: JsonNode): Recallable =
  ## getRegexPatternSet
  ## Returns the <a>RegexPatternSet</a> specified by <code>RegexPatternSetId</code>.
  ##   body: JObject (required)
  var body_600543 = newJObject()
  if body != nil:
    body_600543 = body
  result = call_600542.call(nil, nil, nil, nil, body_600543)

var getRegexPatternSet* = Call_GetRegexPatternSet_600529(
    name: "getRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRegexPatternSet",
    validator: validate_GetRegexPatternSet_600530, base: "/",
    url: url_GetRegexPatternSet_600531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRule_600544 = ref object of OpenApiRestCall_599368
proc url_GetRule_600546(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRule_600545(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a>Rule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRule</code> request.
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
  var valid_600547 = header.getOrDefault("X-Amz-Date")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-Date", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Security-Token")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Security-Token", valid_600548
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600549 = header.getOrDefault("X-Amz-Target")
  valid_600549 = validateParameter(valid_600549, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRule"))
  if valid_600549 != nil:
    section.add "X-Amz-Target", valid_600549
  var valid_600550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600550 = validateParameter(valid_600550, JString, required = false,
                                 default = nil)
  if valid_600550 != nil:
    section.add "X-Amz-Content-Sha256", valid_600550
  var valid_600551 = header.getOrDefault("X-Amz-Algorithm")
  valid_600551 = validateParameter(valid_600551, JString, required = false,
                                 default = nil)
  if valid_600551 != nil:
    section.add "X-Amz-Algorithm", valid_600551
  var valid_600552 = header.getOrDefault("X-Amz-Signature")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Signature", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-SignedHeaders", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Credential")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Credential", valid_600554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600556: Call_GetRule_600544; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>Rule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRule</code> request.
  ## 
  let valid = call_600556.validator(path, query, header, formData, body)
  let scheme = call_600556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600556.url(scheme.get, call_600556.host, call_600556.base,
                         call_600556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600556, url, valid)

proc call*(call_600557: Call_GetRule_600544; body: JsonNode): Recallable =
  ## getRule
  ## Returns the <a>Rule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRule</code> request.
  ##   body: JObject (required)
  var body_600558 = newJObject()
  if body != nil:
    body_600558 = body
  result = call_600557.call(nil, nil, nil, nil, body_600558)

var getRule* = Call_GetRule_600544(name: "getRule", meth: HttpMethod.HttpPost,
                                host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRule",
                                validator: validate_GetRule_600545, base: "/",
                                url: url_GetRule_600546,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRuleGroup_600559 = ref object of OpenApiRestCall_599368
proc url_GetRuleGroup_600561(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRuleGroup_600560(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the <a>RuleGroup</a> that is specified by the <code>RuleGroupId</code> that you included in the <code>GetRuleGroup</code> request.</p> <p>To view the rules in a rule group, use <a>ListActivatedRulesInRuleGroup</a>.</p>
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
  var valid_600562 = header.getOrDefault("X-Amz-Date")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Date", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Security-Token")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Security-Token", valid_600563
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600564 = header.getOrDefault("X-Amz-Target")
  valid_600564 = validateParameter(valid_600564, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRuleGroup"))
  if valid_600564 != nil:
    section.add "X-Amz-Target", valid_600564
  var valid_600565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600565 = validateParameter(valid_600565, JString, required = false,
                                 default = nil)
  if valid_600565 != nil:
    section.add "X-Amz-Content-Sha256", valid_600565
  var valid_600566 = header.getOrDefault("X-Amz-Algorithm")
  valid_600566 = validateParameter(valid_600566, JString, required = false,
                                 default = nil)
  if valid_600566 != nil:
    section.add "X-Amz-Algorithm", valid_600566
  var valid_600567 = header.getOrDefault("X-Amz-Signature")
  valid_600567 = validateParameter(valid_600567, JString, required = false,
                                 default = nil)
  if valid_600567 != nil:
    section.add "X-Amz-Signature", valid_600567
  var valid_600568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-SignedHeaders", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Credential")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Credential", valid_600569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600571: Call_GetRuleGroup_600559; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the <a>RuleGroup</a> that is specified by the <code>RuleGroupId</code> that you included in the <code>GetRuleGroup</code> request.</p> <p>To view the rules in a rule group, use <a>ListActivatedRulesInRuleGroup</a>.</p>
  ## 
  let valid = call_600571.validator(path, query, header, formData, body)
  let scheme = call_600571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600571.url(scheme.get, call_600571.host, call_600571.base,
                         call_600571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600571, url, valid)

proc call*(call_600572: Call_GetRuleGroup_600559; body: JsonNode): Recallable =
  ## getRuleGroup
  ## <p>Returns the <a>RuleGroup</a> that is specified by the <code>RuleGroupId</code> that you included in the <code>GetRuleGroup</code> request.</p> <p>To view the rules in a rule group, use <a>ListActivatedRulesInRuleGroup</a>.</p>
  ##   body: JObject (required)
  var body_600573 = newJObject()
  if body != nil:
    body_600573 = body
  result = call_600572.call(nil, nil, nil, nil, body_600573)

var getRuleGroup* = Call_GetRuleGroup_600559(name: "getRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRuleGroup",
    validator: validate_GetRuleGroup_600560, base: "/", url: url_GetRuleGroup_600561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSampledRequests_600574 = ref object of OpenApiRestCall_599368
proc url_GetSampledRequests_600576(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSampledRequests_600575(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
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
  var valid_600577 = header.getOrDefault("X-Amz-Date")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Date", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Security-Token")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Security-Token", valid_600578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600579 = header.getOrDefault("X-Amz-Target")
  valid_600579 = validateParameter(valid_600579, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetSampledRequests"))
  if valid_600579 != nil:
    section.add "X-Amz-Target", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Content-Sha256", valid_600580
  var valid_600581 = header.getOrDefault("X-Amz-Algorithm")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "X-Amz-Algorithm", valid_600581
  var valid_600582 = header.getOrDefault("X-Amz-Signature")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Signature", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-SignedHeaders", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Credential")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Credential", valid_600584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600586: Call_GetSampledRequests_600574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
  ## 
  let valid = call_600586.validator(path, query, header, formData, body)
  let scheme = call_600586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600586.url(scheme.get, call_600586.host, call_600586.base,
                         call_600586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600586, url, valid)

proc call*(call_600587: Call_GetSampledRequests_600574; body: JsonNode): Recallable =
  ## getSampledRequests
  ## <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
  ##   body: JObject (required)
  var body_600588 = newJObject()
  if body != nil:
    body_600588 = body
  result = call_600587.call(nil, nil, nil, nil, body_600588)

var getSampledRequests* = Call_GetSampledRequests_600574(
    name: "getSampledRequests", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetSampledRequests",
    validator: validate_GetSampledRequests_600575, base: "/",
    url: url_GetSampledRequests_600576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSizeConstraintSet_600589 = ref object of OpenApiRestCall_599368
proc url_GetSizeConstraintSet_600591(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSizeConstraintSet_600590(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a>SizeConstraintSet</a> specified by <code>SizeConstraintSetId</code>.
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
  var valid_600592 = header.getOrDefault("X-Amz-Date")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Date", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Security-Token")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Security-Token", valid_600593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600594 = header.getOrDefault("X-Amz-Target")
  valid_600594 = validateParameter(valid_600594, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetSizeConstraintSet"))
  if valid_600594 != nil:
    section.add "X-Amz-Target", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Content-Sha256", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Algorithm")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Algorithm", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Signature")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Signature", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-SignedHeaders", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Credential")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Credential", valid_600599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600601: Call_GetSizeConstraintSet_600589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>SizeConstraintSet</a> specified by <code>SizeConstraintSetId</code>.
  ## 
  let valid = call_600601.validator(path, query, header, formData, body)
  let scheme = call_600601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600601.url(scheme.get, call_600601.host, call_600601.base,
                         call_600601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600601, url, valid)

proc call*(call_600602: Call_GetSizeConstraintSet_600589; body: JsonNode): Recallable =
  ## getSizeConstraintSet
  ## Returns the <a>SizeConstraintSet</a> specified by <code>SizeConstraintSetId</code>.
  ##   body: JObject (required)
  var body_600603 = newJObject()
  if body != nil:
    body_600603 = body
  result = call_600602.call(nil, nil, nil, nil, body_600603)

var getSizeConstraintSet* = Call_GetSizeConstraintSet_600589(
    name: "getSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetSizeConstraintSet",
    validator: validate_GetSizeConstraintSet_600590, base: "/",
    url: url_GetSizeConstraintSet_600591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSqlInjectionMatchSet_600604 = ref object of OpenApiRestCall_599368
proc url_GetSqlInjectionMatchSet_600606(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSqlInjectionMatchSet_600605(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a>SqlInjectionMatchSet</a> that is specified by <code>SqlInjectionMatchSetId</code>.
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
  var valid_600607 = header.getOrDefault("X-Amz-Date")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Date", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Security-Token")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Security-Token", valid_600608
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600609 = header.getOrDefault("X-Amz-Target")
  valid_600609 = validateParameter(valid_600609, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetSqlInjectionMatchSet"))
  if valid_600609 != nil:
    section.add "X-Amz-Target", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Content-Sha256", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Algorithm")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Algorithm", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Signature")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Signature", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-SignedHeaders", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Credential")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Credential", valid_600614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600616: Call_GetSqlInjectionMatchSet_600604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>SqlInjectionMatchSet</a> that is specified by <code>SqlInjectionMatchSetId</code>.
  ## 
  let valid = call_600616.validator(path, query, header, formData, body)
  let scheme = call_600616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600616.url(scheme.get, call_600616.host, call_600616.base,
                         call_600616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600616, url, valid)

proc call*(call_600617: Call_GetSqlInjectionMatchSet_600604; body: JsonNode): Recallable =
  ## getSqlInjectionMatchSet
  ## Returns the <a>SqlInjectionMatchSet</a> that is specified by <code>SqlInjectionMatchSetId</code>.
  ##   body: JObject (required)
  var body_600618 = newJObject()
  if body != nil:
    body_600618 = body
  result = call_600617.call(nil, nil, nil, nil, body_600618)

var getSqlInjectionMatchSet* = Call_GetSqlInjectionMatchSet_600604(
    name: "getSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetSqlInjectionMatchSet",
    validator: validate_GetSqlInjectionMatchSet_600605, base: "/",
    url: url_GetSqlInjectionMatchSet_600606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebACL_600619 = ref object of OpenApiRestCall_599368
proc url_GetWebACL_600621(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWebACL_600620(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a>WebACL</a> that is specified by <code>WebACLId</code>.
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
  var valid_600622 = header.getOrDefault("X-Amz-Date")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Date", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Security-Token")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Security-Token", valid_600623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600624 = header.getOrDefault("X-Amz-Target")
  valid_600624 = validateParameter(valid_600624, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetWebACL"))
  if valid_600624 != nil:
    section.add "X-Amz-Target", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Content-Sha256", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Algorithm")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Algorithm", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Signature")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Signature", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-SignedHeaders", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Credential")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Credential", valid_600629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600631: Call_GetWebACL_600619; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>WebACL</a> that is specified by <code>WebACLId</code>.
  ## 
  let valid = call_600631.validator(path, query, header, formData, body)
  let scheme = call_600631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600631.url(scheme.get, call_600631.host, call_600631.base,
                         call_600631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600631, url, valid)

proc call*(call_600632: Call_GetWebACL_600619; body: JsonNode): Recallable =
  ## getWebACL
  ## Returns the <a>WebACL</a> that is specified by <code>WebACLId</code>.
  ##   body: JObject (required)
  var body_600633 = newJObject()
  if body != nil:
    body_600633 = body
  result = call_600632.call(nil, nil, nil, nil, body_600633)

var getWebACL* = Call_GetWebACL_600619(name: "getWebACL", meth: HttpMethod.HttpPost,
                                    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetWebACL",
                                    validator: validate_GetWebACL_600620,
                                    base: "/", url: url_GetWebACL_600621,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebACLForResource_600634 = ref object of OpenApiRestCall_599368
proc url_GetWebACLForResource_600636(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetWebACLForResource_600635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the web ACL for the specified resource, either an application load balancer or Amazon API Gateway stage.
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
  var valid_600637 = header.getOrDefault("X-Amz-Date")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Date", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Security-Token")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Security-Token", valid_600638
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600639 = header.getOrDefault("X-Amz-Target")
  valid_600639 = validateParameter(valid_600639, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetWebACLForResource"))
  if valid_600639 != nil:
    section.add "X-Amz-Target", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Content-Sha256", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Algorithm")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Algorithm", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Signature")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Signature", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-SignedHeaders", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Credential")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Credential", valid_600644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600646: Call_GetWebACLForResource_600634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the web ACL for the specified resource, either an application load balancer or Amazon API Gateway stage.
  ## 
  let valid = call_600646.validator(path, query, header, formData, body)
  let scheme = call_600646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600646.url(scheme.get, call_600646.host, call_600646.base,
                         call_600646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600646, url, valid)

proc call*(call_600647: Call_GetWebACLForResource_600634; body: JsonNode): Recallable =
  ## getWebACLForResource
  ## Returns the web ACL for the specified resource, either an application load balancer or Amazon API Gateway stage.
  ##   body: JObject (required)
  var body_600648 = newJObject()
  if body != nil:
    body_600648 = body
  result = call_600647.call(nil, nil, nil, nil, body_600648)

var getWebACLForResource* = Call_GetWebACLForResource_600634(
    name: "getWebACLForResource", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetWebACLForResource",
    validator: validate_GetWebACLForResource_600635, base: "/",
    url: url_GetWebACLForResource_600636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetXssMatchSet_600649 = ref object of OpenApiRestCall_599368
proc url_GetXssMatchSet_600651(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetXssMatchSet_600650(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns the <a>XssMatchSet</a> that is specified by <code>XssMatchSetId</code>.
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
  var valid_600652 = header.getOrDefault("X-Amz-Date")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Date", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Security-Token")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Security-Token", valid_600653
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600654 = header.getOrDefault("X-Amz-Target")
  valid_600654 = validateParameter(valid_600654, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetXssMatchSet"))
  if valid_600654 != nil:
    section.add "X-Amz-Target", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Content-Sha256", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Algorithm")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Algorithm", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Signature")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Signature", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-SignedHeaders", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-Credential")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Credential", valid_600659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600661: Call_GetXssMatchSet_600649; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>XssMatchSet</a> that is specified by <code>XssMatchSetId</code>.
  ## 
  let valid = call_600661.validator(path, query, header, formData, body)
  let scheme = call_600661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600661.url(scheme.get, call_600661.host, call_600661.base,
                         call_600661.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600661, url, valid)

proc call*(call_600662: Call_GetXssMatchSet_600649; body: JsonNode): Recallable =
  ## getXssMatchSet
  ## Returns the <a>XssMatchSet</a> that is specified by <code>XssMatchSetId</code>.
  ##   body: JObject (required)
  var body_600663 = newJObject()
  if body != nil:
    body_600663 = body
  result = call_600662.call(nil, nil, nil, nil, body_600663)

var getXssMatchSet* = Call_GetXssMatchSet_600649(name: "getXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetXssMatchSet",
    validator: validate_GetXssMatchSet_600650, base: "/", url: url_GetXssMatchSet_600651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActivatedRulesInRuleGroup_600664 = ref object of OpenApiRestCall_599368
proc url_ListActivatedRulesInRuleGroup_600666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListActivatedRulesInRuleGroup_600665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>ActivatedRule</a> objects.
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
  var valid_600667 = header.getOrDefault("X-Amz-Date")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Date", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Security-Token")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Security-Token", valid_600668
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600669 = header.getOrDefault("X-Amz-Target")
  valid_600669 = validateParameter(valid_600669, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListActivatedRulesInRuleGroup"))
  if valid_600669 != nil:
    section.add "X-Amz-Target", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Content-Sha256", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Algorithm")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Algorithm", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Signature")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Signature", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-SignedHeaders", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-Credential")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Credential", valid_600674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600676: Call_ListActivatedRulesInRuleGroup_600664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>ActivatedRule</a> objects.
  ## 
  let valid = call_600676.validator(path, query, header, formData, body)
  let scheme = call_600676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600676.url(scheme.get, call_600676.host, call_600676.base,
                         call_600676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600676, url, valid)

proc call*(call_600677: Call_ListActivatedRulesInRuleGroup_600664; body: JsonNode): Recallable =
  ## listActivatedRulesInRuleGroup
  ## Returns an array of <a>ActivatedRule</a> objects.
  ##   body: JObject (required)
  var body_600678 = newJObject()
  if body != nil:
    body_600678 = body
  result = call_600677.call(nil, nil, nil, nil, body_600678)

var listActivatedRulesInRuleGroup* = Call_ListActivatedRulesInRuleGroup_600664(
    name: "listActivatedRulesInRuleGroup", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListActivatedRulesInRuleGroup",
    validator: validate_ListActivatedRulesInRuleGroup_600665, base: "/",
    url: url_ListActivatedRulesInRuleGroup_600666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListByteMatchSets_600679 = ref object of OpenApiRestCall_599368
proc url_ListByteMatchSets_600681(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListByteMatchSets_600680(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns an array of <a>ByteMatchSetSummary</a> objects.
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
  var valid_600682 = header.getOrDefault("X-Amz-Date")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Date", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Security-Token")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Security-Token", valid_600683
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600684 = header.getOrDefault("X-Amz-Target")
  valid_600684 = validateParameter(valid_600684, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListByteMatchSets"))
  if valid_600684 != nil:
    section.add "X-Amz-Target", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Content-Sha256", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Algorithm")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Algorithm", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Signature")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Signature", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-SignedHeaders", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Credential")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Credential", valid_600689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600691: Call_ListByteMatchSets_600679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>ByteMatchSetSummary</a> objects.
  ## 
  let valid = call_600691.validator(path, query, header, formData, body)
  let scheme = call_600691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600691.url(scheme.get, call_600691.host, call_600691.base,
                         call_600691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600691, url, valid)

proc call*(call_600692: Call_ListByteMatchSets_600679; body: JsonNode): Recallable =
  ## listByteMatchSets
  ## Returns an array of <a>ByteMatchSetSummary</a> objects.
  ##   body: JObject (required)
  var body_600693 = newJObject()
  if body != nil:
    body_600693 = body
  result = call_600692.call(nil, nil, nil, nil, body_600693)

var listByteMatchSets* = Call_ListByteMatchSets_600679(name: "listByteMatchSets",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListByteMatchSets",
    validator: validate_ListByteMatchSets_600680, base: "/",
    url: url_ListByteMatchSets_600681, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGeoMatchSets_600694 = ref object of OpenApiRestCall_599368
proc url_ListGeoMatchSets_600696(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGeoMatchSets_600695(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns an array of <a>GeoMatchSetSummary</a> objects in the response.
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
  var valid_600697 = header.getOrDefault("X-Amz-Date")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Date", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Security-Token")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Security-Token", valid_600698
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600699 = header.getOrDefault("X-Amz-Target")
  valid_600699 = validateParameter(valid_600699, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListGeoMatchSets"))
  if valid_600699 != nil:
    section.add "X-Amz-Target", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Content-Sha256", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Algorithm")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Algorithm", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Signature")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Signature", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-SignedHeaders", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-Credential")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-Credential", valid_600704
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600706: Call_ListGeoMatchSets_600694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>GeoMatchSetSummary</a> objects in the response.
  ## 
  let valid = call_600706.validator(path, query, header, formData, body)
  let scheme = call_600706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600706.url(scheme.get, call_600706.host, call_600706.base,
                         call_600706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600706, url, valid)

proc call*(call_600707: Call_ListGeoMatchSets_600694; body: JsonNode): Recallable =
  ## listGeoMatchSets
  ## Returns an array of <a>GeoMatchSetSummary</a> objects in the response.
  ##   body: JObject (required)
  var body_600708 = newJObject()
  if body != nil:
    body_600708 = body
  result = call_600707.call(nil, nil, nil, nil, body_600708)

var listGeoMatchSets* = Call_ListGeoMatchSets_600694(name: "listGeoMatchSets",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListGeoMatchSets",
    validator: validate_ListGeoMatchSets_600695, base: "/",
    url: url_ListGeoMatchSets_600696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_600709 = ref object of OpenApiRestCall_599368
proc url_ListIPSets_600711(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListIPSets_600710(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>IPSetSummary</a> objects in the response.
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
  var valid_600712 = header.getOrDefault("X-Amz-Date")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Date", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Security-Token")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Security-Token", valid_600713
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600714 = header.getOrDefault("X-Amz-Target")
  valid_600714 = validateParameter(valid_600714, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListIPSets"))
  if valid_600714 != nil:
    section.add "X-Amz-Target", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Content-Sha256", valid_600715
  var valid_600716 = header.getOrDefault("X-Amz-Algorithm")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Algorithm", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Signature")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Signature", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-SignedHeaders", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-Credential")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Credential", valid_600719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600721: Call_ListIPSets_600709; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>IPSetSummary</a> objects in the response.
  ## 
  let valid = call_600721.validator(path, query, header, formData, body)
  let scheme = call_600721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600721.url(scheme.get, call_600721.host, call_600721.base,
                         call_600721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600721, url, valid)

proc call*(call_600722: Call_ListIPSets_600709; body: JsonNode): Recallable =
  ## listIPSets
  ## Returns an array of <a>IPSetSummary</a> objects in the response.
  ##   body: JObject (required)
  var body_600723 = newJObject()
  if body != nil:
    body_600723 = body
  result = call_600722.call(nil, nil, nil, nil, body_600723)

var listIPSets* = Call_ListIPSets_600709(name: "listIPSets",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListIPSets",
                                      validator: validate_ListIPSets_600710,
                                      base: "/", url: url_ListIPSets_600711,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggingConfigurations_600724 = ref object of OpenApiRestCall_599368
proc url_ListLoggingConfigurations_600726(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLoggingConfigurations_600725(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>LoggingConfiguration</a> objects.
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
  var valid_600727 = header.getOrDefault("X-Amz-Date")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Date", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Security-Token")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Security-Token", valid_600728
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600729 = header.getOrDefault("X-Amz-Target")
  valid_600729 = validateParameter(valid_600729, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListLoggingConfigurations"))
  if valid_600729 != nil:
    section.add "X-Amz-Target", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-Content-Sha256", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Algorithm")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Algorithm", valid_600731
  var valid_600732 = header.getOrDefault("X-Amz-Signature")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Signature", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-SignedHeaders", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Credential")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Credential", valid_600734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600736: Call_ListLoggingConfigurations_600724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>LoggingConfiguration</a> objects.
  ## 
  let valid = call_600736.validator(path, query, header, formData, body)
  let scheme = call_600736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600736.url(scheme.get, call_600736.host, call_600736.base,
                         call_600736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600736, url, valid)

proc call*(call_600737: Call_ListLoggingConfigurations_600724; body: JsonNode): Recallable =
  ## listLoggingConfigurations
  ## Returns an array of <a>LoggingConfiguration</a> objects.
  ##   body: JObject (required)
  var body_600738 = newJObject()
  if body != nil:
    body_600738 = body
  result = call_600737.call(nil, nil, nil, nil, body_600738)

var listLoggingConfigurations* = Call_ListLoggingConfigurations_600724(
    name: "listLoggingConfigurations", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListLoggingConfigurations",
    validator: validate_ListLoggingConfigurations_600725, base: "/",
    url: url_ListLoggingConfigurations_600726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRateBasedRules_600739 = ref object of OpenApiRestCall_599368
proc url_ListRateBasedRules_600741(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRateBasedRules_600740(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns an array of <a>RuleSummary</a> objects.
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
  var valid_600742 = header.getOrDefault("X-Amz-Date")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-Date", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-Security-Token")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Security-Token", valid_600743
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600744 = header.getOrDefault("X-Amz-Target")
  valid_600744 = validateParameter(valid_600744, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRateBasedRules"))
  if valid_600744 != nil:
    section.add "X-Amz-Target", valid_600744
  var valid_600745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-Content-Sha256", valid_600745
  var valid_600746 = header.getOrDefault("X-Amz-Algorithm")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Algorithm", valid_600746
  var valid_600747 = header.getOrDefault("X-Amz-Signature")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Signature", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-SignedHeaders", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Credential")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Credential", valid_600749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600751: Call_ListRateBasedRules_600739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleSummary</a> objects.
  ## 
  let valid = call_600751.validator(path, query, header, formData, body)
  let scheme = call_600751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600751.url(scheme.get, call_600751.host, call_600751.base,
                         call_600751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600751, url, valid)

proc call*(call_600752: Call_ListRateBasedRules_600739; body: JsonNode): Recallable =
  ## listRateBasedRules
  ## Returns an array of <a>RuleSummary</a> objects.
  ##   body: JObject (required)
  var body_600753 = newJObject()
  if body != nil:
    body_600753 = body
  result = call_600752.call(nil, nil, nil, nil, body_600753)

var listRateBasedRules* = Call_ListRateBasedRules_600739(
    name: "listRateBasedRules", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRateBasedRules",
    validator: validate_ListRateBasedRules_600740, base: "/",
    url: url_ListRateBasedRules_600741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegexMatchSets_600754 = ref object of OpenApiRestCall_599368
proc url_ListRegexMatchSets_600756(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRegexMatchSets_600755(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns an array of <a>RegexMatchSetSummary</a> objects.
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
  var valid_600757 = header.getOrDefault("X-Amz-Date")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-Date", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-Security-Token")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Security-Token", valid_600758
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600759 = header.getOrDefault("X-Amz-Target")
  valid_600759 = validateParameter(valid_600759, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRegexMatchSets"))
  if valid_600759 != nil:
    section.add "X-Amz-Target", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Content-Sha256", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Algorithm")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Algorithm", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Signature")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Signature", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-SignedHeaders", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Credential")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Credential", valid_600764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600766: Call_ListRegexMatchSets_600754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RegexMatchSetSummary</a> objects.
  ## 
  let valid = call_600766.validator(path, query, header, formData, body)
  let scheme = call_600766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600766.url(scheme.get, call_600766.host, call_600766.base,
                         call_600766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600766, url, valid)

proc call*(call_600767: Call_ListRegexMatchSets_600754; body: JsonNode): Recallable =
  ## listRegexMatchSets
  ## Returns an array of <a>RegexMatchSetSummary</a> objects.
  ##   body: JObject (required)
  var body_600768 = newJObject()
  if body != nil:
    body_600768 = body
  result = call_600767.call(nil, nil, nil, nil, body_600768)

var listRegexMatchSets* = Call_ListRegexMatchSets_600754(
    name: "listRegexMatchSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRegexMatchSets",
    validator: validate_ListRegexMatchSets_600755, base: "/",
    url: url_ListRegexMatchSets_600756, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegexPatternSets_600769 = ref object of OpenApiRestCall_599368
proc url_ListRegexPatternSets_600771(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRegexPatternSets_600770(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>RegexPatternSetSummary</a> objects.
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
  var valid_600772 = header.getOrDefault("X-Amz-Date")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Date", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Security-Token")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Security-Token", valid_600773
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600774 = header.getOrDefault("X-Amz-Target")
  valid_600774 = validateParameter(valid_600774, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRegexPatternSets"))
  if valid_600774 != nil:
    section.add "X-Amz-Target", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Content-Sha256", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Algorithm")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Algorithm", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Signature")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Signature", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-SignedHeaders", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Credential")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Credential", valid_600779
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600781: Call_ListRegexPatternSets_600769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RegexPatternSetSummary</a> objects.
  ## 
  let valid = call_600781.validator(path, query, header, formData, body)
  let scheme = call_600781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600781.url(scheme.get, call_600781.host, call_600781.base,
                         call_600781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600781, url, valid)

proc call*(call_600782: Call_ListRegexPatternSets_600769; body: JsonNode): Recallable =
  ## listRegexPatternSets
  ## Returns an array of <a>RegexPatternSetSummary</a> objects.
  ##   body: JObject (required)
  var body_600783 = newJObject()
  if body != nil:
    body_600783 = body
  result = call_600782.call(nil, nil, nil, nil, body_600783)

var listRegexPatternSets* = Call_ListRegexPatternSets_600769(
    name: "listRegexPatternSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRegexPatternSets",
    validator: validate_ListRegexPatternSets_600770, base: "/",
    url: url_ListRegexPatternSets_600771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForWebACL_600784 = ref object of OpenApiRestCall_599368
proc url_ListResourcesForWebACL_600786(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourcesForWebACL_600785(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of resources associated with the specified web ACL.
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
  var valid_600787 = header.getOrDefault("X-Amz-Date")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Date", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Security-Token")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Security-Token", valid_600788
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600789 = header.getOrDefault("X-Amz-Target")
  valid_600789 = validateParameter(valid_600789, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListResourcesForWebACL"))
  if valid_600789 != nil:
    section.add "X-Amz-Target", valid_600789
  var valid_600790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "X-Amz-Content-Sha256", valid_600790
  var valid_600791 = header.getOrDefault("X-Amz-Algorithm")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "X-Amz-Algorithm", valid_600791
  var valid_600792 = header.getOrDefault("X-Amz-Signature")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-Signature", valid_600792
  var valid_600793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "X-Amz-SignedHeaders", valid_600793
  var valid_600794 = header.getOrDefault("X-Amz-Credential")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "X-Amz-Credential", valid_600794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600796: Call_ListResourcesForWebACL_600784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources associated with the specified web ACL.
  ## 
  let valid = call_600796.validator(path, query, header, formData, body)
  let scheme = call_600796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600796.url(scheme.get, call_600796.host, call_600796.base,
                         call_600796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600796, url, valid)

proc call*(call_600797: Call_ListResourcesForWebACL_600784; body: JsonNode): Recallable =
  ## listResourcesForWebACL
  ## Returns an array of resources associated with the specified web ACL.
  ##   body: JObject (required)
  var body_600798 = newJObject()
  if body != nil:
    body_600798 = body
  result = call_600797.call(nil, nil, nil, nil, body_600798)

var listResourcesForWebACL* = Call_ListResourcesForWebACL_600784(
    name: "listResourcesForWebACL", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListResourcesForWebACL",
    validator: validate_ListResourcesForWebACL_600785, base: "/",
    url: url_ListResourcesForWebACL_600786, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuleGroups_600799 = ref object of OpenApiRestCall_599368
proc url_ListRuleGroups_600801(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRuleGroups_600800(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Returns an array of <a>RuleGroup</a> objects.
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
  var valid_600802 = header.getOrDefault("X-Amz-Date")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Date", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Security-Token")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Security-Token", valid_600803
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600804 = header.getOrDefault("X-Amz-Target")
  valid_600804 = validateParameter(valid_600804, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRuleGroups"))
  if valid_600804 != nil:
    section.add "X-Amz-Target", valid_600804
  var valid_600805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600805 = validateParameter(valid_600805, JString, required = false,
                                 default = nil)
  if valid_600805 != nil:
    section.add "X-Amz-Content-Sha256", valid_600805
  var valid_600806 = header.getOrDefault("X-Amz-Algorithm")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Algorithm", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-Signature")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-Signature", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-SignedHeaders", valid_600808
  var valid_600809 = header.getOrDefault("X-Amz-Credential")
  valid_600809 = validateParameter(valid_600809, JString, required = false,
                                 default = nil)
  if valid_600809 != nil:
    section.add "X-Amz-Credential", valid_600809
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600811: Call_ListRuleGroups_600799; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleGroup</a> objects.
  ## 
  let valid = call_600811.validator(path, query, header, formData, body)
  let scheme = call_600811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600811.url(scheme.get, call_600811.host, call_600811.base,
                         call_600811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600811, url, valid)

proc call*(call_600812: Call_ListRuleGroups_600799; body: JsonNode): Recallable =
  ## listRuleGroups
  ## Returns an array of <a>RuleGroup</a> objects.
  ##   body: JObject (required)
  var body_600813 = newJObject()
  if body != nil:
    body_600813 = body
  result = call_600812.call(nil, nil, nil, nil, body_600813)

var listRuleGroups* = Call_ListRuleGroups_600799(name: "listRuleGroups",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRuleGroups",
    validator: validate_ListRuleGroups_600800, base: "/", url: url_ListRuleGroups_600801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRules_600814 = ref object of OpenApiRestCall_599368
proc url_ListRules_600816(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRules_600815(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>RuleSummary</a> objects.
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
  var valid_600817 = header.getOrDefault("X-Amz-Date")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Date", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-Security-Token")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-Security-Token", valid_600818
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600819 = header.getOrDefault("X-Amz-Target")
  valid_600819 = validateParameter(valid_600819, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRules"))
  if valid_600819 != nil:
    section.add "X-Amz-Target", valid_600819
  var valid_600820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "X-Amz-Content-Sha256", valid_600820
  var valid_600821 = header.getOrDefault("X-Amz-Algorithm")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-Algorithm", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-Signature")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Signature", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-SignedHeaders", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Credential")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Credential", valid_600824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600826: Call_ListRules_600814; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleSummary</a> objects.
  ## 
  let valid = call_600826.validator(path, query, header, formData, body)
  let scheme = call_600826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600826.url(scheme.get, call_600826.host, call_600826.base,
                         call_600826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600826, url, valid)

proc call*(call_600827: Call_ListRules_600814; body: JsonNode): Recallable =
  ## listRules
  ## Returns an array of <a>RuleSummary</a> objects.
  ##   body: JObject (required)
  var body_600828 = newJObject()
  if body != nil:
    body_600828 = body
  result = call_600827.call(nil, nil, nil, nil, body_600828)

var listRules* = Call_ListRules_600814(name: "listRules", meth: HttpMethod.HttpPost,
                                    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRules",
                                    validator: validate_ListRules_600815,
                                    base: "/", url: url_ListRules_600816,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSizeConstraintSets_600829 = ref object of OpenApiRestCall_599368
proc url_ListSizeConstraintSets_600831(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSizeConstraintSets_600830(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>SizeConstraintSetSummary</a> objects.
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
  var valid_600832 = header.getOrDefault("X-Amz-Date")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "X-Amz-Date", valid_600832
  var valid_600833 = header.getOrDefault("X-Amz-Security-Token")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "X-Amz-Security-Token", valid_600833
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600834 = header.getOrDefault("X-Amz-Target")
  valid_600834 = validateParameter(valid_600834, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListSizeConstraintSets"))
  if valid_600834 != nil:
    section.add "X-Amz-Target", valid_600834
  var valid_600835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Content-Sha256", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Algorithm")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Algorithm", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Signature")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Signature", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-SignedHeaders", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Credential")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Credential", valid_600839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600841: Call_ListSizeConstraintSets_600829; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>SizeConstraintSetSummary</a> objects.
  ## 
  let valid = call_600841.validator(path, query, header, formData, body)
  let scheme = call_600841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600841.url(scheme.get, call_600841.host, call_600841.base,
                         call_600841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600841, url, valid)

proc call*(call_600842: Call_ListSizeConstraintSets_600829; body: JsonNode): Recallable =
  ## listSizeConstraintSets
  ## Returns an array of <a>SizeConstraintSetSummary</a> objects.
  ##   body: JObject (required)
  var body_600843 = newJObject()
  if body != nil:
    body_600843 = body
  result = call_600842.call(nil, nil, nil, nil, body_600843)

var listSizeConstraintSets* = Call_ListSizeConstraintSets_600829(
    name: "listSizeConstraintSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListSizeConstraintSets",
    validator: validate_ListSizeConstraintSets_600830, base: "/",
    url: url_ListSizeConstraintSets_600831, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSqlInjectionMatchSets_600844 = ref object of OpenApiRestCall_599368
proc url_ListSqlInjectionMatchSets_600846(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSqlInjectionMatchSets_600845(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>SqlInjectionMatchSet</a> objects.
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
  var valid_600847 = header.getOrDefault("X-Amz-Date")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Date", valid_600847
  var valid_600848 = header.getOrDefault("X-Amz-Security-Token")
  valid_600848 = validateParameter(valid_600848, JString, required = false,
                                 default = nil)
  if valid_600848 != nil:
    section.add "X-Amz-Security-Token", valid_600848
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600849 = header.getOrDefault("X-Amz-Target")
  valid_600849 = validateParameter(valid_600849, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListSqlInjectionMatchSets"))
  if valid_600849 != nil:
    section.add "X-Amz-Target", valid_600849
  var valid_600850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Content-Sha256", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Algorithm")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Algorithm", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Signature")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Signature", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-SignedHeaders", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Credential")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Credential", valid_600854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600856: Call_ListSqlInjectionMatchSets_600844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>SqlInjectionMatchSet</a> objects.
  ## 
  let valid = call_600856.validator(path, query, header, formData, body)
  let scheme = call_600856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600856.url(scheme.get, call_600856.host, call_600856.base,
                         call_600856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600856, url, valid)

proc call*(call_600857: Call_ListSqlInjectionMatchSets_600844; body: JsonNode): Recallable =
  ## listSqlInjectionMatchSets
  ## Returns an array of <a>SqlInjectionMatchSet</a> objects.
  ##   body: JObject (required)
  var body_600858 = newJObject()
  if body != nil:
    body_600858 = body
  result = call_600857.call(nil, nil, nil, nil, body_600858)

var listSqlInjectionMatchSets* = Call_ListSqlInjectionMatchSets_600844(
    name: "listSqlInjectionMatchSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListSqlInjectionMatchSets",
    validator: validate_ListSqlInjectionMatchSets_600845, base: "/",
    url: url_ListSqlInjectionMatchSets_600846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedRuleGroups_600859 = ref object of OpenApiRestCall_599368
proc url_ListSubscribedRuleGroups_600861(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSubscribedRuleGroups_600860(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>RuleGroup</a> objects that you are subscribed to.
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
  var valid_600862 = header.getOrDefault("X-Amz-Date")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-Date", valid_600862
  var valid_600863 = header.getOrDefault("X-Amz-Security-Token")
  valid_600863 = validateParameter(valid_600863, JString, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "X-Amz-Security-Token", valid_600863
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600864 = header.getOrDefault("X-Amz-Target")
  valid_600864 = validateParameter(valid_600864, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListSubscribedRuleGroups"))
  if valid_600864 != nil:
    section.add "X-Amz-Target", valid_600864
  var valid_600865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600865 = validateParameter(valid_600865, JString, required = false,
                                 default = nil)
  if valid_600865 != nil:
    section.add "X-Amz-Content-Sha256", valid_600865
  var valid_600866 = header.getOrDefault("X-Amz-Algorithm")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-Algorithm", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-Signature")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-Signature", valid_600867
  var valid_600868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "X-Amz-SignedHeaders", valid_600868
  var valid_600869 = header.getOrDefault("X-Amz-Credential")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Credential", valid_600869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600871: Call_ListSubscribedRuleGroups_600859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleGroup</a> objects that you are subscribed to.
  ## 
  let valid = call_600871.validator(path, query, header, formData, body)
  let scheme = call_600871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600871.url(scheme.get, call_600871.host, call_600871.base,
                         call_600871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600871, url, valid)

proc call*(call_600872: Call_ListSubscribedRuleGroups_600859; body: JsonNode): Recallable =
  ## listSubscribedRuleGroups
  ## Returns an array of <a>RuleGroup</a> objects that you are subscribed to.
  ##   body: JObject (required)
  var body_600873 = newJObject()
  if body != nil:
    body_600873 = body
  result = call_600872.call(nil, nil, nil, nil, body_600873)

var listSubscribedRuleGroups* = Call_ListSubscribedRuleGroups_600859(
    name: "listSubscribedRuleGroups", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListSubscribedRuleGroups",
    validator: validate_ListSubscribedRuleGroups_600860, base: "/",
    url: url_ListSubscribedRuleGroups_600861, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600874 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600876(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600875(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600877 = header.getOrDefault("X-Amz-Date")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Date", valid_600877
  var valid_600878 = header.getOrDefault("X-Amz-Security-Token")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "X-Amz-Security-Token", valid_600878
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600879 = header.getOrDefault("X-Amz-Target")
  valid_600879 = validateParameter(valid_600879, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListTagsForResource"))
  if valid_600879 != nil:
    section.add "X-Amz-Target", valid_600879
  var valid_600880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "X-Amz-Content-Sha256", valid_600880
  var valid_600881 = header.getOrDefault("X-Amz-Algorithm")
  valid_600881 = validateParameter(valid_600881, JString, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "X-Amz-Algorithm", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-Signature")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Signature", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-SignedHeaders", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Credential")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Credential", valid_600884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600886: Call_ListTagsForResource_600874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600886.validator(path, query, header, formData, body)
  let scheme = call_600886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600886.url(scheme.get, call_600886.host, call_600886.base,
                         call_600886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600886, url, valid)

proc call*(call_600887: Call_ListTagsForResource_600874; body: JsonNode): Recallable =
  ## listTagsForResource
  ##   body: JObject (required)
  var body_600888 = newJObject()
  if body != nil:
    body_600888 = body
  result = call_600887.call(nil, nil, nil, nil, body_600888)

var listTagsForResource* = Call_ListTagsForResource_600874(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListTagsForResource",
    validator: validate_ListTagsForResource_600875, base: "/",
    url: url_ListTagsForResource_600876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebACLs_600889 = ref object of OpenApiRestCall_599368
proc url_ListWebACLs_600891(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListWebACLs_600890(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an array of <a>WebACLSummary</a> objects in the response.
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
  var valid_600892 = header.getOrDefault("X-Amz-Date")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Date", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-Security-Token")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-Security-Token", valid_600893
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600894 = header.getOrDefault("X-Amz-Target")
  valid_600894 = validateParameter(valid_600894, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListWebACLs"))
  if valid_600894 != nil:
    section.add "X-Amz-Target", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Content-Sha256", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Algorithm")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Algorithm", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Signature")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Signature", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-SignedHeaders", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Credential")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Credential", valid_600899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600901: Call_ListWebACLs_600889; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>WebACLSummary</a> objects in the response.
  ## 
  let valid = call_600901.validator(path, query, header, formData, body)
  let scheme = call_600901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600901.url(scheme.get, call_600901.host, call_600901.base,
                         call_600901.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600901, url, valid)

proc call*(call_600902: Call_ListWebACLs_600889; body: JsonNode): Recallable =
  ## listWebACLs
  ## Returns an array of <a>WebACLSummary</a> objects in the response.
  ##   body: JObject (required)
  var body_600903 = newJObject()
  if body != nil:
    body_600903 = body
  result = call_600902.call(nil, nil, nil, nil, body_600903)

var listWebACLs* = Call_ListWebACLs_600889(name: "listWebACLs",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListWebACLs",
                                        validator: validate_ListWebACLs_600890,
                                        base: "/", url: url_ListWebACLs_600891,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListXssMatchSets_600904 = ref object of OpenApiRestCall_599368
proc url_ListXssMatchSets_600906(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListXssMatchSets_600905(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Returns an array of <a>XssMatchSet</a> objects.
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
  var valid_600907 = header.getOrDefault("X-Amz-Date")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Date", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Security-Token")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Security-Token", valid_600908
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600909 = header.getOrDefault("X-Amz-Target")
  valid_600909 = validateParameter(valid_600909, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListXssMatchSets"))
  if valid_600909 != nil:
    section.add "X-Amz-Target", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Content-Sha256", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-Algorithm")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-Algorithm", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Signature")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Signature", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-SignedHeaders", valid_600913
  var valid_600914 = header.getOrDefault("X-Amz-Credential")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Credential", valid_600914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600916: Call_ListXssMatchSets_600904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>XssMatchSet</a> objects.
  ## 
  let valid = call_600916.validator(path, query, header, formData, body)
  let scheme = call_600916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600916.url(scheme.get, call_600916.host, call_600916.base,
                         call_600916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600916, url, valid)

proc call*(call_600917: Call_ListXssMatchSets_600904; body: JsonNode): Recallable =
  ## listXssMatchSets
  ## Returns an array of <a>XssMatchSet</a> objects.
  ##   body: JObject (required)
  var body_600918 = newJObject()
  if body != nil:
    body_600918 = body
  result = call_600917.call(nil, nil, nil, nil, body_600918)

var listXssMatchSets* = Call_ListXssMatchSets_600904(name: "listXssMatchSets",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListXssMatchSets",
    validator: validate_ListXssMatchSets_600905, base: "/",
    url: url_ListXssMatchSets_600906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingConfiguration_600919 = ref object of OpenApiRestCall_599368
proc url_PutLoggingConfiguration_600921(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLoggingConfiguration_600920(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Associates a <a>LoggingConfiguration</a> with a specified web ACL.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. However, if you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
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
  var valid_600922 = header.getOrDefault("X-Amz-Date")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Date", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Security-Token")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Security-Token", valid_600923
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600924 = header.getOrDefault("X-Amz-Target")
  valid_600924 = validateParameter(valid_600924, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.PutLoggingConfiguration"))
  if valid_600924 != nil:
    section.add "X-Amz-Target", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Content-Sha256", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Algorithm")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Algorithm", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Signature")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Signature", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-SignedHeaders", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Credential")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Credential", valid_600929
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600931: Call_PutLoggingConfiguration_600919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a <a>LoggingConfiguration</a> with a specified web ACL.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. However, if you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
  ## 
  let valid = call_600931.validator(path, query, header, formData, body)
  let scheme = call_600931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600931.url(scheme.get, call_600931.host, call_600931.base,
                         call_600931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600931, url, valid)

proc call*(call_600932: Call_PutLoggingConfiguration_600919; body: JsonNode): Recallable =
  ## putLoggingConfiguration
  ## <p>Associates a <a>LoggingConfiguration</a> with a specified web ACL.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. However, if you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_600933 = newJObject()
  if body != nil:
    body_600933 = body
  result = call_600932.call(nil, nil, nil, nil, body_600933)

var putLoggingConfiguration* = Call_PutLoggingConfiguration_600919(
    name: "putLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.PutLoggingConfiguration",
    validator: validate_PutLoggingConfiguration_600920, base: "/",
    url: url_PutLoggingConfiguration_600921, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPermissionPolicy_600934 = ref object of OpenApiRestCall_599368
proc url_PutPermissionPolicy_600936(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutPermissionPolicy_600935(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Attaches a IAM policy to the specified resource. The only supported use for this action is to share a RuleGroup across accounts.</p> <p>The <code>PutPermissionPolicy</code> is subject to the following restrictions:</p> <ul> <li> <p>You can attach only one policy with each <code>PutPermissionPolicy</code> request.</p> </li> <li> <p>The policy must include an <code>Effect</code>, <code>Action</code> and <code>Principal</code>. </p> </li> <li> <p> <code>Effect</code> must specify <code>Allow</code>.</p> </li> <li> <p>The <code>Action</code> in the policy must be <code>waf:UpdateWebACL</code>, <code>waf-regional:UpdateWebACL</code>, <code>waf:GetRuleGroup</code> and <code>waf-regional:GetRuleGroup</code> . Any extra or wildcard actions in the policy will be rejected.</p> </li> <li> <p>The policy cannot include a <code>Resource</code> parameter.</p> </li> <li> <p>The ARN in the request must be a valid WAF RuleGroup ARN and the RuleGroup must exist in the same region.</p> </li> <li> <p>The user making the request must be the owner of the RuleGroup.</p> </li> <li> <p>Your policy must be composed using IAM Policy version 2012-10-17.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a>. </p> <p>An example of a valid policy parameter is shown in the Examples section below.</p>
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
  var valid_600937 = header.getOrDefault("X-Amz-Date")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Date", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Security-Token")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Security-Token", valid_600938
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600939 = header.getOrDefault("X-Amz-Target")
  valid_600939 = validateParameter(valid_600939, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.PutPermissionPolicy"))
  if valid_600939 != nil:
    section.add "X-Amz-Target", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Content-Sha256", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Algorithm")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Algorithm", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-Signature")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Signature", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-SignedHeaders", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Credential")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Credential", valid_600944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600946: Call_PutPermissionPolicy_600934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a IAM policy to the specified resource. The only supported use for this action is to share a RuleGroup across accounts.</p> <p>The <code>PutPermissionPolicy</code> is subject to the following restrictions:</p> <ul> <li> <p>You can attach only one policy with each <code>PutPermissionPolicy</code> request.</p> </li> <li> <p>The policy must include an <code>Effect</code>, <code>Action</code> and <code>Principal</code>. </p> </li> <li> <p> <code>Effect</code> must specify <code>Allow</code>.</p> </li> <li> <p>The <code>Action</code> in the policy must be <code>waf:UpdateWebACL</code>, <code>waf-regional:UpdateWebACL</code>, <code>waf:GetRuleGroup</code> and <code>waf-regional:GetRuleGroup</code> . Any extra or wildcard actions in the policy will be rejected.</p> </li> <li> <p>The policy cannot include a <code>Resource</code> parameter.</p> </li> <li> <p>The ARN in the request must be a valid WAF RuleGroup ARN and the RuleGroup must exist in the same region.</p> </li> <li> <p>The user making the request must be the owner of the RuleGroup.</p> </li> <li> <p>Your policy must be composed using IAM Policy version 2012-10-17.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a>. </p> <p>An example of a valid policy parameter is shown in the Examples section below.</p>
  ## 
  let valid = call_600946.validator(path, query, header, formData, body)
  let scheme = call_600946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600946.url(scheme.get, call_600946.host, call_600946.base,
                         call_600946.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600946, url, valid)

proc call*(call_600947: Call_PutPermissionPolicy_600934; body: JsonNode): Recallable =
  ## putPermissionPolicy
  ## <p>Attaches a IAM policy to the specified resource. The only supported use for this action is to share a RuleGroup across accounts.</p> <p>The <code>PutPermissionPolicy</code> is subject to the following restrictions:</p> <ul> <li> <p>You can attach only one policy with each <code>PutPermissionPolicy</code> request.</p> </li> <li> <p>The policy must include an <code>Effect</code>, <code>Action</code> and <code>Principal</code>. </p> </li> <li> <p> <code>Effect</code> must specify <code>Allow</code>.</p> </li> <li> <p>The <code>Action</code> in the policy must be <code>waf:UpdateWebACL</code>, <code>waf-regional:UpdateWebACL</code>, <code>waf:GetRuleGroup</code> and <code>waf-regional:GetRuleGroup</code> . Any extra or wildcard actions in the policy will be rejected.</p> </li> <li> <p>The policy cannot include a <code>Resource</code> parameter.</p> </li> <li> <p>The ARN in the request must be a valid WAF RuleGroup ARN and the RuleGroup must exist in the same region.</p> </li> <li> <p>The user making the request must be the owner of the RuleGroup.</p> </li> <li> <p>Your policy must be composed using IAM Policy version 2012-10-17.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a>. </p> <p>An example of a valid policy parameter is shown in the Examples section below.</p>
  ##   body: JObject (required)
  var body_600948 = newJObject()
  if body != nil:
    body_600948 = body
  result = call_600947.call(nil, nil, nil, nil, body_600948)

var putPermissionPolicy* = Call_PutPermissionPolicy_600934(
    name: "putPermissionPolicy", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.PutPermissionPolicy",
    validator: validate_PutPermissionPolicy_600935, base: "/",
    url: url_PutPermissionPolicy_600936, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600949 = ref object of OpenApiRestCall_599368
proc url_TagResource_600951(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600950(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600952 = header.getOrDefault("X-Amz-Date")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Date", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Security-Token")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Security-Token", valid_600953
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600954 = header.getOrDefault("X-Amz-Target")
  valid_600954 = validateParameter(valid_600954, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.TagResource"))
  if valid_600954 != nil:
    section.add "X-Amz-Target", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Content-Sha256", valid_600955
  var valid_600956 = header.getOrDefault("X-Amz-Algorithm")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "X-Amz-Algorithm", valid_600956
  var valid_600957 = header.getOrDefault("X-Amz-Signature")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "X-Amz-Signature", valid_600957
  var valid_600958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "X-Amz-SignedHeaders", valid_600958
  var valid_600959 = header.getOrDefault("X-Amz-Credential")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "X-Amz-Credential", valid_600959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600961: Call_TagResource_600949; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600961.validator(path, query, header, formData, body)
  let scheme = call_600961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600961.url(scheme.get, call_600961.host, call_600961.base,
                         call_600961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600961, url, valid)

proc call*(call_600962: Call_TagResource_600949; body: JsonNode): Recallable =
  ## tagResource
  ##   body: JObject (required)
  var body_600963 = newJObject()
  if body != nil:
    body_600963 = body
  result = call_600962.call(nil, nil, nil, nil, body_600963)

var tagResource* = Call_TagResource_600949(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.TagResource",
                                        validator: validate_TagResource_600950,
                                        base: "/", url: url_TagResource_600951,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600964 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600966(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600965(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600967 = header.getOrDefault("X-Amz-Date")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Date", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-Security-Token")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Security-Token", valid_600968
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600969 = header.getOrDefault("X-Amz-Target")
  valid_600969 = validateParameter(valid_600969, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UntagResource"))
  if valid_600969 != nil:
    section.add "X-Amz-Target", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Content-Sha256", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Algorithm")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Algorithm", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Signature")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Signature", valid_600972
  var valid_600973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-SignedHeaders", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-Credential")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-Credential", valid_600974
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600976: Call_UntagResource_600964; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600976.validator(path, query, header, formData, body)
  let scheme = call_600976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600976.url(scheme.get, call_600976.host, call_600976.base,
                         call_600976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600976, url, valid)

proc call*(call_600977: Call_UntagResource_600964; body: JsonNode): Recallable =
  ## untagResource
  ##   body: JObject (required)
  var body_600978 = newJObject()
  if body != nil:
    body_600978 = body
  result = call_600977.call(nil, nil, nil, nil, body_600978)

var untagResource* = Call_UntagResource_600964(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UntagResource",
    validator: validate_UntagResource_600965, base: "/", url: url_UntagResource_600966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateByteMatchSet_600979 = ref object of OpenApiRestCall_599368
proc url_UpdateByteMatchSet_600981(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateByteMatchSet_600980(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>ByteMatchTuple</a> objects (filters) in a <a>ByteMatchSet</a>. For each <code>ByteMatchTuple</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>ByteMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspect, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The bytes (typically a string that corresponds with ASCII characters) that you want AWS WAF to look for. For more information, including how you specify the values for the AWS WAF API and the AWS CLI or SDKs, see <code>TargetString</code> in the <a>ByteMatchTuple</a> data type. </p> </li> <li> <p>Where to look, such as at the beginning or the end of a query string.</p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p>For example, you can add a <code>ByteMatchSetUpdate</code> object that matches web requests in which <code>User-Agent</code> headers contain the string <code>BadBot</code>. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>ByteMatchSet.</code> For more information, see <a>CreateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateByteMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_600982 = header.getOrDefault("X-Amz-Date")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Date", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Security-Token")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Security-Token", valid_600983
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600984 = header.getOrDefault("X-Amz-Target")
  valid_600984 = validateParameter(valid_600984, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateByteMatchSet"))
  if valid_600984 != nil:
    section.add "X-Amz-Target", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-Content-Sha256", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Algorithm")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Algorithm", valid_600986
  var valid_600987 = header.getOrDefault("X-Amz-Signature")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-Signature", valid_600987
  var valid_600988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-SignedHeaders", valid_600988
  var valid_600989 = header.getOrDefault("X-Amz-Credential")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Credential", valid_600989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600991: Call_UpdateByteMatchSet_600979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>ByteMatchTuple</a> objects (filters) in a <a>ByteMatchSet</a>. For each <code>ByteMatchTuple</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>ByteMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspect, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The bytes (typically a string that corresponds with ASCII characters) that you want AWS WAF to look for. For more information, including how you specify the values for the AWS WAF API and the AWS CLI or SDKs, see <code>TargetString</code> in the <a>ByteMatchTuple</a> data type. </p> </li> <li> <p>Where to look, such as at the beginning or the end of a query string.</p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p>For example, you can add a <code>ByteMatchSetUpdate</code> object that matches web requests in which <code>User-Agent</code> headers contain the string <code>BadBot</code>. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>ByteMatchSet.</code> For more information, see <a>CreateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateByteMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_600991.validator(path, query, header, formData, body)
  let scheme = call_600991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600991.url(scheme.get, call_600991.host, call_600991.base,
                         call_600991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600991, url, valid)

proc call*(call_600992: Call_UpdateByteMatchSet_600979; body: JsonNode): Recallable =
  ## updateByteMatchSet
  ## <p>Inserts or deletes <a>ByteMatchTuple</a> objects (filters) in a <a>ByteMatchSet</a>. For each <code>ByteMatchTuple</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>ByteMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspect, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The bytes (typically a string that corresponds with ASCII characters) that you want AWS WAF to look for. For more information, including how you specify the values for the AWS WAF API and the AWS CLI or SDKs, see <code>TargetString</code> in the <a>ByteMatchTuple</a> data type. </p> </li> <li> <p>Where to look, such as at the beginning or the end of a query string.</p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p>For example, you can add a <code>ByteMatchSetUpdate</code> object that matches web requests in which <code>User-Agent</code> headers contain the string <code>BadBot</code>. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>ByteMatchSet.</code> For more information, see <a>CreateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateByteMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_600993 = newJObject()
  if body != nil:
    body_600993 = body
  result = call_600992.call(nil, nil, nil, nil, body_600993)

var updateByteMatchSet* = Call_UpdateByteMatchSet_600979(
    name: "updateByteMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateByteMatchSet",
    validator: validate_UpdateByteMatchSet_600980, base: "/",
    url: url_UpdateByteMatchSet_600981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGeoMatchSet_600994 = ref object of OpenApiRestCall_599368
proc url_UpdateGeoMatchSet_600996(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGeoMatchSet_600995(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>GeoMatchConstraint</a> objects in an <code>GeoMatchSet</code>. For each <code>GeoMatchConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>GeoMatchConstraint</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The <code>Type</code>. The only valid value for <code>Type</code> is <code>Country</code>.</p> </li> <li> <p>The <code>Value</code>, which is a two character code for the country to add to the <code>GeoMatchConstraint</code> object. Valid codes are listed in <a>GeoMatchConstraint$Value</a>.</p> </li> </ul> <p>To create and configure an <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateGeoMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSet</code> request to specify the country that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>GeoMatchSet</code>, you specify the country that you want to add and/or the country that you want to delete. If you want to change a country, you delete the existing country and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_600997 = header.getOrDefault("X-Amz-Date")
  valid_600997 = validateParameter(valid_600997, JString, required = false,
                                 default = nil)
  if valid_600997 != nil:
    section.add "X-Amz-Date", valid_600997
  var valid_600998 = header.getOrDefault("X-Amz-Security-Token")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "X-Amz-Security-Token", valid_600998
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600999 = header.getOrDefault("X-Amz-Target")
  valid_600999 = validateParameter(valid_600999, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateGeoMatchSet"))
  if valid_600999 != nil:
    section.add "X-Amz-Target", valid_600999
  var valid_601000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "X-Amz-Content-Sha256", valid_601000
  var valid_601001 = header.getOrDefault("X-Amz-Algorithm")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Algorithm", valid_601001
  var valid_601002 = header.getOrDefault("X-Amz-Signature")
  valid_601002 = validateParameter(valid_601002, JString, required = false,
                                 default = nil)
  if valid_601002 != nil:
    section.add "X-Amz-Signature", valid_601002
  var valid_601003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "X-Amz-SignedHeaders", valid_601003
  var valid_601004 = header.getOrDefault("X-Amz-Credential")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "X-Amz-Credential", valid_601004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601006: Call_UpdateGeoMatchSet_600994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>GeoMatchConstraint</a> objects in an <code>GeoMatchSet</code>. For each <code>GeoMatchConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>GeoMatchConstraint</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The <code>Type</code>. The only valid value for <code>Type</code> is <code>Country</code>.</p> </li> <li> <p>The <code>Value</code>, which is a two character code for the country to add to the <code>GeoMatchConstraint</code> object. Valid codes are listed in <a>GeoMatchConstraint$Value</a>.</p> </li> </ul> <p>To create and configure an <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateGeoMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSet</code> request to specify the country that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>GeoMatchSet</code>, you specify the country that you want to add and/or the country that you want to delete. If you want to change a country, you delete the existing country and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601006.validator(path, query, header, formData, body)
  let scheme = call_601006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601006.url(scheme.get, call_601006.host, call_601006.base,
                         call_601006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601006, url, valid)

proc call*(call_601007: Call_UpdateGeoMatchSet_600994; body: JsonNode): Recallable =
  ## updateGeoMatchSet
  ## <p>Inserts or deletes <a>GeoMatchConstraint</a> objects in an <code>GeoMatchSet</code>. For each <code>GeoMatchConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>GeoMatchConstraint</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The <code>Type</code>. The only valid value for <code>Type</code> is <code>Country</code>.</p> </li> <li> <p>The <code>Value</code>, which is a two character code for the country to add to the <code>GeoMatchConstraint</code> object. Valid codes are listed in <a>GeoMatchConstraint$Value</a>.</p> </li> </ul> <p>To create and configure an <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateGeoMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSet</code> request to specify the country that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>GeoMatchSet</code>, you specify the country that you want to add and/or the country that you want to delete. If you want to change a country, you delete the existing country and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601008 = newJObject()
  if body != nil:
    body_601008 = body
  result = call_601007.call(nil, nil, nil, nil, body_601008)

var updateGeoMatchSet* = Call_UpdateGeoMatchSet_600994(name: "updateGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateGeoMatchSet",
    validator: validate_UpdateGeoMatchSet_600995, base: "/",
    url: url_UpdateGeoMatchSet_600996, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_601009 = ref object of OpenApiRestCall_599368
proc url_UpdateIPSet_601011(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateIPSet_601010(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>IPSetDescriptor</a> objects in an <code>IPSet</code>. For each <code>IPSetDescriptor</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>IPSetDescriptor</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The IP address version, <code>IPv4</code> or <code>IPv6</code>. </p> </li> <li> <p>The IP address in CIDR notation, for example, <code>192.0.2.0/24</code> (for the range of IP addresses from <code>192.0.2.0</code> to <code>192.0.2.255</code>) or <code>192.0.2.44/32</code> (for the individual IP address <code>192.0.2.44</code>). </p> </li> </ul> <p>AWS WAF supports IPv4 address ranges: /8 and any range between /16 through /32. AWS WAF supports IPv6 address ranges: /24, /32, /48, /56, /64, and /128. For more information about CIDR notation, see the Wikipedia entry <a href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">Classless Inter-Domain Routing</a>.</p> <p>IPv6 addresses can be represented using any of the following formats:</p> <ul> <li> <p>1111:0000:0000:0000:0000:0000:0000:0111/128</p> </li> <li> <p>1111:0:0:0:0:0:0:0111/128</p> </li> <li> <p>1111::0111/128</p> </li> <li> <p>1111::111/128</p> </li> </ul> <p>You use an <code>IPSet</code> to specify which web requests you want to allow or block based on the IP addresses that the requests originated from. For example, if you're receiving a lot of requests from one or a small number of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that specifies those IP addresses, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateIPSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>IPSet</code>, you specify the IP addresses that you want to add and/or the IP addresses that you want to delete. If you want to change an IP address, you delete the existing IP address and add the new one.</p> <p>You can insert a maximum of 1000 addresses in a single request.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601012 = header.getOrDefault("X-Amz-Date")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Date", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Security-Token")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Security-Token", valid_601013
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601014 = header.getOrDefault("X-Amz-Target")
  valid_601014 = validateParameter(valid_601014, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateIPSet"))
  if valid_601014 != nil:
    section.add "X-Amz-Target", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-Content-Sha256", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Algorithm")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Algorithm", valid_601016
  var valid_601017 = header.getOrDefault("X-Amz-Signature")
  valid_601017 = validateParameter(valid_601017, JString, required = false,
                                 default = nil)
  if valid_601017 != nil:
    section.add "X-Amz-Signature", valid_601017
  var valid_601018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-SignedHeaders", valid_601018
  var valid_601019 = header.getOrDefault("X-Amz-Credential")
  valid_601019 = validateParameter(valid_601019, JString, required = false,
                                 default = nil)
  if valid_601019 != nil:
    section.add "X-Amz-Credential", valid_601019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601021: Call_UpdateIPSet_601009; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>IPSetDescriptor</a> objects in an <code>IPSet</code>. For each <code>IPSetDescriptor</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>IPSetDescriptor</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The IP address version, <code>IPv4</code> or <code>IPv6</code>. </p> </li> <li> <p>The IP address in CIDR notation, for example, <code>192.0.2.0/24</code> (for the range of IP addresses from <code>192.0.2.0</code> to <code>192.0.2.255</code>) or <code>192.0.2.44/32</code> (for the individual IP address <code>192.0.2.44</code>). </p> </li> </ul> <p>AWS WAF supports IPv4 address ranges: /8 and any range between /16 through /32. AWS WAF supports IPv6 address ranges: /24, /32, /48, /56, /64, and /128. For more information about CIDR notation, see the Wikipedia entry <a href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">Classless Inter-Domain Routing</a>.</p> <p>IPv6 addresses can be represented using any of the following formats:</p> <ul> <li> <p>1111:0000:0000:0000:0000:0000:0000:0111/128</p> </li> <li> <p>1111:0:0:0:0:0:0:0111/128</p> </li> <li> <p>1111::0111/128</p> </li> <li> <p>1111::111/128</p> </li> </ul> <p>You use an <code>IPSet</code> to specify which web requests you want to allow or block based on the IP addresses that the requests originated from. For example, if you're receiving a lot of requests from one or a small number of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that specifies those IP addresses, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateIPSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>IPSet</code>, you specify the IP addresses that you want to add and/or the IP addresses that you want to delete. If you want to change an IP address, you delete the existing IP address and add the new one.</p> <p>You can insert a maximum of 1000 addresses in a single request.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601021.validator(path, query, header, formData, body)
  let scheme = call_601021.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601021.url(scheme.get, call_601021.host, call_601021.base,
                         call_601021.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601021, url, valid)

proc call*(call_601022: Call_UpdateIPSet_601009; body: JsonNode): Recallable =
  ## updateIPSet
  ## <p>Inserts or deletes <a>IPSetDescriptor</a> objects in an <code>IPSet</code>. For each <code>IPSetDescriptor</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>IPSetDescriptor</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The IP address version, <code>IPv4</code> or <code>IPv6</code>. </p> </li> <li> <p>The IP address in CIDR notation, for example, <code>192.0.2.0/24</code> (for the range of IP addresses from <code>192.0.2.0</code> to <code>192.0.2.255</code>) or <code>192.0.2.44/32</code> (for the individual IP address <code>192.0.2.44</code>). </p> </li> </ul> <p>AWS WAF supports IPv4 address ranges: /8 and any range between /16 through /32. AWS WAF supports IPv6 address ranges: /24, /32, /48, /56, /64, and /128. For more information about CIDR notation, see the Wikipedia entry <a href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">Classless Inter-Domain Routing</a>.</p> <p>IPv6 addresses can be represented using any of the following formats:</p> <ul> <li> <p>1111:0000:0000:0000:0000:0000:0000:0111/128</p> </li> <li> <p>1111:0:0:0:0:0:0:0111/128</p> </li> <li> <p>1111::0111/128</p> </li> <li> <p>1111::111/128</p> </li> </ul> <p>You use an <code>IPSet</code> to specify which web requests you want to allow or block based on the IP addresses that the requests originated from. For example, if you're receiving a lot of requests from one or a small number of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that specifies those IP addresses, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateIPSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>IPSet</code>, you specify the IP addresses that you want to add and/or the IP addresses that you want to delete. If you want to change an IP address, you delete the existing IP address and add the new one.</p> <p>You can insert a maximum of 1000 addresses in a single request.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601023 = newJObject()
  if body != nil:
    body_601023 = body
  result = call_601022.call(nil, nil, nil, nil, body_601023)

var updateIPSet* = Call_UpdateIPSet_601009(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateIPSet",
                                        validator: validate_UpdateIPSet_601010,
                                        base: "/", url: url_UpdateIPSet_601011,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRateBasedRule_601024 = ref object of OpenApiRestCall_599368
proc url_UpdateRateBasedRule_601026(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRateBasedRule_601025(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>Predicate</a> objects in a rule and updates the <code>RateLimit</code> in the rule. </p> <p>Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to block or count. The <code>RateLimit</code> specifies the number of requests every five minutes that triggers the rule.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request must match all the predicates and exceed the <code>RateLimit</code> to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions much be received at a rate of more than 15,000 every five minutes. If the rate drops below this limit, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p>
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
  var valid_601027 = header.getOrDefault("X-Amz-Date")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Date", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Security-Token")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Security-Token", valid_601028
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601029 = header.getOrDefault("X-Amz-Target")
  valid_601029 = validateParameter(valid_601029, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRateBasedRule"))
  if valid_601029 != nil:
    section.add "X-Amz-Target", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Content-Sha256", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Algorithm")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Algorithm", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Signature")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Signature", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-SignedHeaders", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-Credential")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-Credential", valid_601034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_UpdateRateBasedRule_601024; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>Predicate</a> objects in a rule and updates the <code>RateLimit</code> in the rule. </p> <p>Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to block or count. The <code>RateLimit</code> specifies the number of requests every five minutes that triggers the rule.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request must match all the predicates and exceed the <code>RateLimit</code> to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions much be received at a rate of more than 15,000 every five minutes. If the rate drops below this limit, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p>
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601036, url, valid)

proc call*(call_601037: Call_UpdateRateBasedRule_601024; body: JsonNode): Recallable =
  ## updateRateBasedRule
  ## <p>Inserts or deletes <a>Predicate</a> objects in a rule and updates the <code>RateLimit</code> in the rule. </p> <p>Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to block or count. The <code>RateLimit</code> specifies the number of requests every five minutes that triggers the rule.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request must match all the predicates and exceed the <code>RateLimit</code> to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions much be received at a rate of more than 15,000 every five minutes. If the rate drops below this limit, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p>
  ##   body: JObject (required)
  var body_601038 = newJObject()
  if body != nil:
    body_601038 = body
  result = call_601037.call(nil, nil, nil, nil, body_601038)

var updateRateBasedRule* = Call_UpdateRateBasedRule_601024(
    name: "updateRateBasedRule", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRateBasedRule",
    validator: validate_UpdateRateBasedRule_601025, base: "/",
    url: url_UpdateRateBasedRule_601026, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegexMatchSet_601039 = ref object of OpenApiRestCall_599368
proc url_UpdateRegexMatchSet_601041(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRegexMatchSet_601040(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>RegexMatchTuple</a> objects (filters) in a <a>RegexMatchSet</a>. For each <code>RegexMatchSetUpdate</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>RegexMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspectupdate, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The identifier of the pattern (a regular expression) that you want AWS WAF to look for. For more information, see <a>RegexPatternSet</a>. </p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p> For example, you can create a <code>RegexPatternSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexMatchSet.</code> For more information, see <a>CreateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the identifier of the <code>RegexPatternSet</code> that contain the regular expression patters you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601042 = header.getOrDefault("X-Amz-Date")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Date", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Security-Token")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Security-Token", valid_601043
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601044 = header.getOrDefault("X-Amz-Target")
  valid_601044 = validateParameter(valid_601044, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRegexMatchSet"))
  if valid_601044 != nil:
    section.add "X-Amz-Target", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Content-Sha256", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Algorithm")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Algorithm", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Signature")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Signature", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-SignedHeaders", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Credential")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Credential", valid_601049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601051: Call_UpdateRegexMatchSet_601039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>RegexMatchTuple</a> objects (filters) in a <a>RegexMatchSet</a>. For each <code>RegexMatchSetUpdate</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>RegexMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspectupdate, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The identifier of the pattern (a regular expression) that you want AWS WAF to look for. For more information, see <a>RegexPatternSet</a>. </p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p> For example, you can create a <code>RegexPatternSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexMatchSet.</code> For more information, see <a>CreateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the identifier of the <code>RegexPatternSet</code> that contain the regular expression patters you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601051.validator(path, query, header, formData, body)
  let scheme = call_601051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601051.url(scheme.get, call_601051.host, call_601051.base,
                         call_601051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601051, url, valid)

proc call*(call_601052: Call_UpdateRegexMatchSet_601039; body: JsonNode): Recallable =
  ## updateRegexMatchSet
  ## <p>Inserts or deletes <a>RegexMatchTuple</a> objects (filters) in a <a>RegexMatchSet</a>. For each <code>RegexMatchSetUpdate</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>RegexMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspectupdate, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The identifier of the pattern (a regular expression) that you want AWS WAF to look for. For more information, see <a>RegexPatternSet</a>. </p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p> For example, you can create a <code>RegexPatternSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexMatchSet.</code> For more information, see <a>CreateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the identifier of the <code>RegexPatternSet</code> that contain the regular expression patters you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601053 = newJObject()
  if body != nil:
    body_601053 = body
  result = call_601052.call(nil, nil, nil, nil, body_601053)

var updateRegexMatchSet* = Call_UpdateRegexMatchSet_601039(
    name: "updateRegexMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRegexMatchSet",
    validator: validate_UpdateRegexMatchSet_601040, base: "/",
    url: url_UpdateRegexMatchSet_601041, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegexPatternSet_601054 = ref object of OpenApiRestCall_599368
proc url_UpdateRegexPatternSet_601056(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRegexPatternSet_601055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <code>RegexPatternString</code> objects in a <a>RegexPatternSet</a>. For each <code>RegexPatternString</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the <code>RegexPatternString</code>.</p> </li> <li> <p>The regular expression pattern that you want to insert or delete. For more information, see <a>RegexPatternSet</a>. </p> </li> </ul> <p> For example, you can create a <code>RegexPatternString</code> such as <code>B[a@]dB[o0]t</code>. AWS WAF will match this <code>RegexPatternString</code> to:</p> <ul> <li> <p>BadBot</p> </li> <li> <p>BadB0t</p> </li> <li> <p>B@dBot</p> </li> <li> <p>B@dB0t</p> </li> </ul> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexPatternSet.</code> For more information, see <a>CreateRegexPatternSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexPatternSet</code> request to specify the regular expression pattern that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601057 = header.getOrDefault("X-Amz-Date")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Date", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Security-Token")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Security-Token", valid_601058
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601059 = header.getOrDefault("X-Amz-Target")
  valid_601059 = validateParameter(valid_601059, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRegexPatternSet"))
  if valid_601059 != nil:
    section.add "X-Amz-Target", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Content-Sha256", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Algorithm")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Algorithm", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Signature")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Signature", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-SignedHeaders", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Credential")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Credential", valid_601064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_UpdateRegexPatternSet_601054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <code>RegexPatternString</code> objects in a <a>RegexPatternSet</a>. For each <code>RegexPatternString</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the <code>RegexPatternString</code>.</p> </li> <li> <p>The regular expression pattern that you want to insert or delete. For more information, see <a>RegexPatternSet</a>. </p> </li> </ul> <p> For example, you can create a <code>RegexPatternString</code> such as <code>B[a@]dB[o0]t</code>. AWS WAF will match this <code>RegexPatternString</code> to:</p> <ul> <li> <p>BadBot</p> </li> <li> <p>BadB0t</p> </li> <li> <p>B@dBot</p> </li> <li> <p>B@dB0t</p> </li> </ul> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexPatternSet.</code> For more information, see <a>CreateRegexPatternSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexPatternSet</code> request to specify the regular expression pattern that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601066, url, valid)

proc call*(call_601067: Call_UpdateRegexPatternSet_601054; body: JsonNode): Recallable =
  ## updateRegexPatternSet
  ## <p>Inserts or deletes <code>RegexPatternString</code> objects in a <a>RegexPatternSet</a>. For each <code>RegexPatternString</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the <code>RegexPatternString</code>.</p> </li> <li> <p>The regular expression pattern that you want to insert or delete. For more information, see <a>RegexPatternSet</a>. </p> </li> </ul> <p> For example, you can create a <code>RegexPatternString</code> such as <code>B[a@]dB[o0]t</code>. AWS WAF will match this <code>RegexPatternString</code> to:</p> <ul> <li> <p>BadBot</p> </li> <li> <p>BadB0t</p> </li> <li> <p>B@dBot</p> </li> <li> <p>B@dB0t</p> </li> </ul> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexPatternSet.</code> For more information, see <a>CreateRegexPatternSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexPatternSet</code> request to specify the regular expression pattern that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601068 = newJObject()
  if body != nil:
    body_601068 = body
  result = call_601067.call(nil, nil, nil, nil, body_601068)

var updateRegexPatternSet* = Call_UpdateRegexPatternSet_601054(
    name: "updateRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRegexPatternSet",
    validator: validate_UpdateRegexPatternSet_601055, base: "/",
    url: url_UpdateRegexPatternSet_601056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRule_601069 = ref object of OpenApiRestCall_599368
proc url_UpdateRule_601071(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRule_601070(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>Predicate</a> objects in a <code>Rule</code>. Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to allow, block, or count. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed, blocked, or counted. For example, suppose that you add the following to a <code>Rule</code>: </p> <ul> <li> <p>A <code>ByteMatchSet</code> that matches the value <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44</code> </p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the <code>Rule</code>. For a request to be blocked, the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code> <i>and</i> the request must originate from the IP address 192.0.2.44.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create the <code>Rule</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to add predicates to the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>ByteMatchSet</code> or <code>IPSet</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601072 = header.getOrDefault("X-Amz-Date")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Date", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Security-Token")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Security-Token", valid_601073
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601074 = header.getOrDefault("X-Amz-Target")
  valid_601074 = validateParameter(valid_601074, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRule"))
  if valid_601074 != nil:
    section.add "X-Amz-Target", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Content-Sha256", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Algorithm")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Algorithm", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Signature")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Signature", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-SignedHeaders", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Credential")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Credential", valid_601079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601081: Call_UpdateRule_601069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>Predicate</a> objects in a <code>Rule</code>. Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to allow, block, or count. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed, blocked, or counted. For example, suppose that you add the following to a <code>Rule</code>: </p> <ul> <li> <p>A <code>ByteMatchSet</code> that matches the value <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44</code> </p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the <code>Rule</code>. For a request to be blocked, the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code> <i>and</i> the request must originate from the IP address 192.0.2.44.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create the <code>Rule</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to add predicates to the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>ByteMatchSet</code> or <code>IPSet</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601081.validator(path, query, header, formData, body)
  let scheme = call_601081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601081.url(scheme.get, call_601081.host, call_601081.base,
                         call_601081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601081, url, valid)

proc call*(call_601082: Call_UpdateRule_601069; body: JsonNode): Recallable =
  ## updateRule
  ## <p>Inserts or deletes <a>Predicate</a> objects in a <code>Rule</code>. Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to allow, block, or count. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed, blocked, or counted. For example, suppose that you add the following to a <code>Rule</code>: </p> <ul> <li> <p>A <code>ByteMatchSet</code> that matches the value <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44</code> </p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the <code>Rule</code>. For a request to be blocked, the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code> <i>and</i> the request must originate from the IP address 192.0.2.44.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create the <code>Rule</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to add predicates to the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>ByteMatchSet</code> or <code>IPSet</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601083 = newJObject()
  if body != nil:
    body_601083 = body
  result = call_601082.call(nil, nil, nil, nil, body_601083)

var updateRule* = Call_UpdateRule_601069(name: "updateRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRule",
                                      validator: validate_UpdateRule_601070,
                                      base: "/", url: url_UpdateRule_601071,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleGroup_601084 = ref object of OpenApiRestCall_599368
proc url_UpdateRuleGroup_601086(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRuleGroup_601085(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>RuleGroup</code>.</p> <p>You can only insert <code>REGULAR</code> rules into a rule group.</p> <p>You can have a maximum of ten rules per rule group.</p> <p>To create and configure a <code>RuleGroup</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>RuleGroup</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRuleGroup</a> request.</p> </li> <li> <p>Submit an <code>UpdateRuleGroup</code> request to add <code>Rules</code> to the <code>RuleGroup</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RuleGroup</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>Rule</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601089 = header.getOrDefault("X-Amz-Target")
  valid_601089 = validateParameter(valid_601089, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRuleGroup"))
  if valid_601089 != nil:
    section.add "X-Amz-Target", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601096: Call_UpdateRuleGroup_601084; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>RuleGroup</code>.</p> <p>You can only insert <code>REGULAR</code> rules into a rule group.</p> <p>You can have a maximum of ten rules per rule group.</p> <p>To create and configure a <code>RuleGroup</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>RuleGroup</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRuleGroup</a> request.</p> </li> <li> <p>Submit an <code>UpdateRuleGroup</code> request to add <code>Rules</code> to the <code>RuleGroup</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RuleGroup</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>Rule</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601096.validator(path, query, header, formData, body)
  let scheme = call_601096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601096.url(scheme.get, call_601096.host, call_601096.base,
                         call_601096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601096, url, valid)

proc call*(call_601097: Call_UpdateRuleGroup_601084; body: JsonNode): Recallable =
  ## updateRuleGroup
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>RuleGroup</code>.</p> <p>You can only insert <code>REGULAR</code> rules into a rule group.</p> <p>You can have a maximum of ten rules per rule group.</p> <p>To create and configure a <code>RuleGroup</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>RuleGroup</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRuleGroup</a> request.</p> </li> <li> <p>Submit an <code>UpdateRuleGroup</code> request to add <code>Rules</code> to the <code>RuleGroup</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RuleGroup</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>Rule</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601098 = newJObject()
  if body != nil:
    body_601098 = body
  result = call_601097.call(nil, nil, nil, nil, body_601098)

var updateRuleGroup* = Call_UpdateRuleGroup_601084(name: "updateRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRuleGroup",
    validator: validate_UpdateRuleGroup_601085, base: "/", url: url_UpdateRuleGroup_601086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSizeConstraintSet_601099 = ref object of OpenApiRestCall_599368
proc url_UpdateSizeConstraintSet_601101(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSizeConstraintSet_601100(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>SizeConstraint</a> objects (filters) in a <a>SizeConstraintSet</a>. For each <code>SizeConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>SizeConstraintSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to evaluate, such as the length of a query string or the length of the <code>User-Agent</code> header.</p> </li> <li> <p>Whether to perform any transformations on the request, such as converting it to lowercase, before checking its length. Note that transformations of the request body are not supported because the AWS resource forwards only the first <code>8192</code> bytes of your request to AWS WAF.</p> <p>You can only specify a single type of TextTransformation.</p> </li> <li> <p>A <code>ComparisonOperator</code> used for evaluating the selected part of the request against the specified <code>Size</code>, such as equals, greater than, less than, and so on.</p> </li> <li> <p>The length, in bytes, that you want AWS WAF to watch for in selected part of the request. The length is computed after applying the transformation.</p> </li> </ul> <p>For example, you can add a <code>SizeConstraintSetUpdate</code> object that matches web requests in which the length of the <code>User-Agent</code> header is greater than 100 bytes. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>SizeConstraintSet.</code> For more information, see <a>CreateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateSizeConstraintSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601104 = header.getOrDefault("X-Amz-Target")
  valid_601104 = validateParameter(valid_601104, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateSizeConstraintSet"))
  if valid_601104 != nil:
    section.add "X-Amz-Target", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Content-Sha256", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Algorithm")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Algorithm", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Signature")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Signature", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-SignedHeaders", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Credential")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Credential", valid_601109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601111: Call_UpdateSizeConstraintSet_601099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>SizeConstraint</a> objects (filters) in a <a>SizeConstraintSet</a>. For each <code>SizeConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>SizeConstraintSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to evaluate, such as the length of a query string or the length of the <code>User-Agent</code> header.</p> </li> <li> <p>Whether to perform any transformations on the request, such as converting it to lowercase, before checking its length. Note that transformations of the request body are not supported because the AWS resource forwards only the first <code>8192</code> bytes of your request to AWS WAF.</p> <p>You can only specify a single type of TextTransformation.</p> </li> <li> <p>A <code>ComparisonOperator</code> used for evaluating the selected part of the request against the specified <code>Size</code>, such as equals, greater than, less than, and so on.</p> </li> <li> <p>The length, in bytes, that you want AWS WAF to watch for in selected part of the request. The length is computed after applying the transformation.</p> </li> </ul> <p>For example, you can add a <code>SizeConstraintSetUpdate</code> object that matches web requests in which the length of the <code>User-Agent</code> header is greater than 100 bytes. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>SizeConstraintSet.</code> For more information, see <a>CreateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateSizeConstraintSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601111.validator(path, query, header, formData, body)
  let scheme = call_601111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601111.url(scheme.get, call_601111.host, call_601111.base,
                         call_601111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601111, url, valid)

proc call*(call_601112: Call_UpdateSizeConstraintSet_601099; body: JsonNode): Recallable =
  ## updateSizeConstraintSet
  ## <p>Inserts or deletes <a>SizeConstraint</a> objects (filters) in a <a>SizeConstraintSet</a>. For each <code>SizeConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>SizeConstraintSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to evaluate, such as the length of a query string or the length of the <code>User-Agent</code> header.</p> </li> <li> <p>Whether to perform any transformations on the request, such as converting it to lowercase, before checking its length. Note that transformations of the request body are not supported because the AWS resource forwards only the first <code>8192</code> bytes of your request to AWS WAF.</p> <p>You can only specify a single type of TextTransformation.</p> </li> <li> <p>A <code>ComparisonOperator</code> used for evaluating the selected part of the request against the specified <code>Size</code>, such as equals, greater than, less than, and so on.</p> </li> <li> <p>The length, in bytes, that you want AWS WAF to watch for in selected part of the request. The length is computed after applying the transformation.</p> </li> </ul> <p>For example, you can add a <code>SizeConstraintSetUpdate</code> object that matches web requests in which the length of the <code>User-Agent</code> header is greater than 100 bytes. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>SizeConstraintSet.</code> For more information, see <a>CreateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateSizeConstraintSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601113 = newJObject()
  if body != nil:
    body_601113 = body
  result = call_601112.call(nil, nil, nil, nil, body_601113)

var updateSizeConstraintSet* = Call_UpdateSizeConstraintSet_601099(
    name: "updateSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateSizeConstraintSet",
    validator: validate_UpdateSizeConstraintSet_601100, base: "/",
    url: url_UpdateSizeConstraintSet_601101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSqlInjectionMatchSet_601114 = ref object of OpenApiRestCall_599368
proc url_UpdateSqlInjectionMatchSet_601116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSqlInjectionMatchSet_601115(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>SqlInjectionMatchTuple</a> objects (filters) in a <a>SqlInjectionMatchSet</a>. For each <code>SqlInjectionMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change a <code>SqlInjectionMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for snippets of malicious SQL code.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>SqlInjectionMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain snippets of SQL code in the query string and you want to block the requests, you can create a <code>SqlInjectionMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateSqlInjectionMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for snippets of SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601117 = header.getOrDefault("X-Amz-Date")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Date", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Security-Token")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Security-Token", valid_601118
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601119 = header.getOrDefault("X-Amz-Target")
  valid_601119 = validateParameter(valid_601119, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateSqlInjectionMatchSet"))
  if valid_601119 != nil:
    section.add "X-Amz-Target", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Content-Sha256", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Algorithm")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Algorithm", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Signature")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Signature", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-SignedHeaders", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Credential")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Credential", valid_601124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601126: Call_UpdateSqlInjectionMatchSet_601114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>SqlInjectionMatchTuple</a> objects (filters) in a <a>SqlInjectionMatchSet</a>. For each <code>SqlInjectionMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change a <code>SqlInjectionMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for snippets of malicious SQL code.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>SqlInjectionMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain snippets of SQL code in the query string and you want to block the requests, you can create a <code>SqlInjectionMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateSqlInjectionMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for snippets of SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601126.validator(path, query, header, formData, body)
  let scheme = call_601126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601126.url(scheme.get, call_601126.host, call_601126.base,
                         call_601126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601126, url, valid)

proc call*(call_601127: Call_UpdateSqlInjectionMatchSet_601114; body: JsonNode): Recallable =
  ## updateSqlInjectionMatchSet
  ## <p>Inserts or deletes <a>SqlInjectionMatchTuple</a> objects (filters) in a <a>SqlInjectionMatchSet</a>. For each <code>SqlInjectionMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change a <code>SqlInjectionMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for snippets of malicious SQL code.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>SqlInjectionMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain snippets of SQL code in the query string and you want to block the requests, you can create a <code>SqlInjectionMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateSqlInjectionMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for snippets of SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601128 = newJObject()
  if body != nil:
    body_601128 = body
  result = call_601127.call(nil, nil, nil, nil, body_601128)

var updateSqlInjectionMatchSet* = Call_UpdateSqlInjectionMatchSet_601114(
    name: "updateSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateSqlInjectionMatchSet",
    validator: validate_UpdateSqlInjectionMatchSet_601115, base: "/",
    url: url_UpdateSqlInjectionMatchSet_601116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebACL_601129 = ref object of OpenApiRestCall_599368
proc url_UpdateWebACL_601131(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateWebACL_601130(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>WebACL</code>. Each <code>Rule</code> identifies web requests that you want to allow, block, or count. When you update a <code>WebACL</code>, you specify the following values:</p> <ul> <li> <p>A default action for the <code>WebACL</code>, either <code>ALLOW</code> or <code>BLOCK</code>. AWS WAF performs the default action if a request doesn't match the criteria in any of the <code>Rules</code> in a <code>WebACL</code>.</p> </li> <li> <p>The <code>Rules</code> that you want to add or delete. If you want to replace one <code>Rule</code> with another, you delete the existing <code>Rule</code> and add the new one.</p> </li> <li> <p>For each <code>Rule</code>, whether you want AWS WAF to allow requests, block requests, or count requests that match the conditions in the <code>Rule</code>.</p> </li> <li> <p>The order in which you want AWS WAF to evaluate the <code>Rules</code> in a <code>WebACL</code>. If you add more than one <code>Rule</code> to a <code>WebACL</code>, AWS WAF evaluates each request against the <code>Rules</code> in order based on the value of <code>Priority</code>. (The <code>Rule</code> that has the lowest value for <code>Priority</code> is evaluated first.) When a web request matches all the predicates (such as <code>ByteMatchSets</code> and <code>IPSets</code>) in a <code>Rule</code>, AWS WAF immediately takes the corresponding action, allow or block, and doesn't evaluate the request against the remaining <code>Rules</code> in the <code>WebACL</code>, if any. </p> </li> </ul> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Create a <code>WebACL</code>. See <a>CreateWebACL</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <code>UpdateWebACL</code> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution. </p> <p>The <code>ActivatedRule</code> can be a rule group. If you specify a rule group as your <code>ActivatedRule</code>, you can exclude specific rules from that rule group.</p> <p>If you already have a rule group associated with a web ACL and want to submit an <code>UpdateWebACL</code> request to exclude certain rules from that rule group, you must first remove the rule group from the web ACL, the re-insert it again, specifying the excluded rules. For details, see <a>ActivatedRule$ExcludedRules</a>. </p> </li> </ol> <p>Be aware that if you try to add a RATE_BASED rule to a web ACL without setting the rule type when first creating the rule, the <a>UpdateWebACL</a> request will fail because the request tries to add a REGULAR rule (the default rule type) with the specified ID, which does not exist. </p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601132 = header.getOrDefault("X-Amz-Date")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Date", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Security-Token")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Security-Token", valid_601133
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601134 = header.getOrDefault("X-Amz-Target")
  valid_601134 = validateParameter(valid_601134, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateWebACL"))
  if valid_601134 != nil:
    section.add "X-Amz-Target", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Content-Sha256", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Algorithm")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Algorithm", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Signature")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Signature", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-SignedHeaders", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Credential")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Credential", valid_601139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601141: Call_UpdateWebACL_601129; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>WebACL</code>. Each <code>Rule</code> identifies web requests that you want to allow, block, or count. When you update a <code>WebACL</code>, you specify the following values:</p> <ul> <li> <p>A default action for the <code>WebACL</code>, either <code>ALLOW</code> or <code>BLOCK</code>. AWS WAF performs the default action if a request doesn't match the criteria in any of the <code>Rules</code> in a <code>WebACL</code>.</p> </li> <li> <p>The <code>Rules</code> that you want to add or delete. If you want to replace one <code>Rule</code> with another, you delete the existing <code>Rule</code> and add the new one.</p> </li> <li> <p>For each <code>Rule</code>, whether you want AWS WAF to allow requests, block requests, or count requests that match the conditions in the <code>Rule</code>.</p> </li> <li> <p>The order in which you want AWS WAF to evaluate the <code>Rules</code> in a <code>WebACL</code>. If you add more than one <code>Rule</code> to a <code>WebACL</code>, AWS WAF evaluates each request against the <code>Rules</code> in order based on the value of <code>Priority</code>. (The <code>Rule</code> that has the lowest value for <code>Priority</code> is evaluated first.) When a web request matches all the predicates (such as <code>ByteMatchSets</code> and <code>IPSets</code>) in a <code>Rule</code>, AWS WAF immediately takes the corresponding action, allow or block, and doesn't evaluate the request against the remaining <code>Rules</code> in the <code>WebACL</code>, if any. </p> </li> </ul> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Create a <code>WebACL</code>. See <a>CreateWebACL</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <code>UpdateWebACL</code> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution. </p> <p>The <code>ActivatedRule</code> can be a rule group. If you specify a rule group as your <code>ActivatedRule</code>, you can exclude specific rules from that rule group.</p> <p>If you already have a rule group associated with a web ACL and want to submit an <code>UpdateWebACL</code> request to exclude certain rules from that rule group, you must first remove the rule group from the web ACL, the re-insert it again, specifying the excluded rules. For details, see <a>ActivatedRule$ExcludedRules</a>. </p> </li> </ol> <p>Be aware that if you try to add a RATE_BASED rule to a web ACL without setting the rule type when first creating the rule, the <a>UpdateWebACL</a> request will fail because the request tries to add a REGULAR rule (the default rule type) with the specified ID, which does not exist. </p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601141.validator(path, query, header, formData, body)
  let scheme = call_601141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601141.url(scheme.get, call_601141.host, call_601141.base,
                         call_601141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601141, url, valid)

proc call*(call_601142: Call_UpdateWebACL_601129; body: JsonNode): Recallable =
  ## updateWebACL
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>WebACL</code>. Each <code>Rule</code> identifies web requests that you want to allow, block, or count. When you update a <code>WebACL</code>, you specify the following values:</p> <ul> <li> <p>A default action for the <code>WebACL</code>, either <code>ALLOW</code> or <code>BLOCK</code>. AWS WAF performs the default action if a request doesn't match the criteria in any of the <code>Rules</code> in a <code>WebACL</code>.</p> </li> <li> <p>The <code>Rules</code> that you want to add or delete. If you want to replace one <code>Rule</code> with another, you delete the existing <code>Rule</code> and add the new one.</p> </li> <li> <p>For each <code>Rule</code>, whether you want AWS WAF to allow requests, block requests, or count requests that match the conditions in the <code>Rule</code>.</p> </li> <li> <p>The order in which you want AWS WAF to evaluate the <code>Rules</code> in a <code>WebACL</code>. If you add more than one <code>Rule</code> to a <code>WebACL</code>, AWS WAF evaluates each request against the <code>Rules</code> in order based on the value of <code>Priority</code>. (The <code>Rule</code> that has the lowest value for <code>Priority</code> is evaluated first.) When a web request matches all the predicates (such as <code>ByteMatchSets</code> and <code>IPSets</code>) in a <code>Rule</code>, AWS WAF immediately takes the corresponding action, allow or block, and doesn't evaluate the request against the remaining <code>Rules</code> in the <code>WebACL</code>, if any. </p> </li> </ul> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Create a <code>WebACL</code>. See <a>CreateWebACL</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <code>UpdateWebACL</code> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution. </p> <p>The <code>ActivatedRule</code> can be a rule group. If you specify a rule group as your <code>ActivatedRule</code>, you can exclude specific rules from that rule group.</p> <p>If you already have a rule group associated with a web ACL and want to submit an <code>UpdateWebACL</code> request to exclude certain rules from that rule group, you must first remove the rule group from the web ACL, the re-insert it again, specifying the excluded rules. For details, see <a>ActivatedRule$ExcludedRules</a>. </p> </li> </ol> <p>Be aware that if you try to add a RATE_BASED rule to a web ACL without setting the rule type when first creating the rule, the <a>UpdateWebACL</a> request will fail because the request tries to add a REGULAR rule (the default rule type) with the specified ID, which does not exist. </p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601143 = newJObject()
  if body != nil:
    body_601143 = body
  result = call_601142.call(nil, nil, nil, nil, body_601143)

var updateWebACL* = Call_UpdateWebACL_601129(name: "updateWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateWebACL",
    validator: validate_UpdateWebACL_601130, base: "/", url: url_UpdateWebACL_601131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateXssMatchSet_601144 = ref object of OpenApiRestCall_599368
proc url_UpdateXssMatchSet_601146(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateXssMatchSet_601145(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Inserts or deletes <a>XssMatchTuple</a> objects (filters) in an <a>XssMatchSet</a>. For each <code>XssMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change an <code>XssMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for cross-site scripting attacks.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>XssMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain cross-site scripting attacks in the request body and you want to block the requests, you can create an <code>XssMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateXssMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateXssMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
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
  var valid_601147 = header.getOrDefault("X-Amz-Date")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Date", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Security-Token")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Security-Token", valid_601148
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601149 = header.getOrDefault("X-Amz-Target")
  valid_601149 = validateParameter(valid_601149, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateXssMatchSet"))
  if valid_601149 != nil:
    section.add "X-Amz-Target", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Content-Sha256", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-Algorithm")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-Algorithm", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Signature")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Signature", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-SignedHeaders", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Credential")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Credential", valid_601154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601156: Call_UpdateXssMatchSet_601144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>XssMatchTuple</a> objects (filters) in an <a>XssMatchSet</a>. For each <code>XssMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change an <code>XssMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for cross-site scripting attacks.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>XssMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain cross-site scripting attacks in the request body and you want to block the requests, you can create an <code>XssMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateXssMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateXssMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_601156.validator(path, query, header, formData, body)
  let scheme = call_601156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601156.url(scheme.get, call_601156.host, call_601156.base,
                         call_601156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601156, url, valid)

proc call*(call_601157: Call_UpdateXssMatchSet_601144; body: JsonNode): Recallable =
  ## updateXssMatchSet
  ## <p>Inserts or deletes <a>XssMatchTuple</a> objects (filters) in an <a>XssMatchSet</a>. For each <code>XssMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change an <code>XssMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for cross-site scripting attacks.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>XssMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain cross-site scripting attacks in the request body and you want to block the requests, you can create an <code>XssMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateXssMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateXssMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_601158 = newJObject()
  if body != nil:
    body_601158 = body
  result = call_601157.call(nil, nil, nil, nil, body_601158)

var updateXssMatchSet* = Call_UpdateXssMatchSet_601144(name: "updateXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateXssMatchSet",
    validator: validate_UpdateXssMatchSet_601145, base: "/",
    url: url_UpdateXssMatchSet_601146, schemes: {Scheme.Https, Scheme.Http})
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
