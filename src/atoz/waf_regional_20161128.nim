
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AssociateWebACL_593774 = ref object of OpenApiRestCall_593437
proc url_AssociateWebACL_593776(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_AssociateWebACL_593775(path: JsonNode; query: JsonNode;
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
  var valid_593888 = header.getOrDefault("X-Amz-Date")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Date", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Security-Token")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Security-Token", valid_593889
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_593903 = header.getOrDefault("X-Amz-Target")
  valid_593903 = validateParameter(valid_593903, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.AssociateWebACL"))
  if valid_593903 != nil:
    section.add "X-Amz-Target", valid_593903
  var valid_593904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Content-Sha256", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Algorithm")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Algorithm", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Signature")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Signature", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-SignedHeaders", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Credential")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Credential", valid_593908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593932: Call_AssociateWebACL_593774; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates a web ACL with a resource, either an application load balancer or Amazon API Gateway stage.
  ## 
  let valid = call_593932.validator(path, query, header, formData, body)
  let scheme = call_593932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593932.url(scheme.get, call_593932.host, call_593932.base,
                         call_593932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593932, url, valid)

proc call*(call_594003: Call_AssociateWebACL_593774; body: JsonNode): Recallable =
  ## associateWebACL
  ## Associates a web ACL with a resource, either an application load balancer or Amazon API Gateway stage.
  ##   body: JObject (required)
  var body_594004 = newJObject()
  if body != nil:
    body_594004 = body
  result = call_594003.call(nil, nil, nil, nil, body_594004)

var associateWebACL* = Call_AssociateWebACL_593774(name: "associateWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.AssociateWebACL",
    validator: validate_AssociateWebACL_593775, base: "/", url: url_AssociateWebACL_593776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateByteMatchSet_594043 = ref object of OpenApiRestCall_593437
proc url_CreateByteMatchSet_594045(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateByteMatchSet_594044(path: JsonNode; query: JsonNode;
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
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Security-Token")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Security-Token", valid_594047
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594048 = header.getOrDefault("X-Amz-Target")
  valid_594048 = validateParameter(valid_594048, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateByteMatchSet"))
  if valid_594048 != nil:
    section.add "X-Amz-Target", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594055: Call_CreateByteMatchSet_594043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>ByteMatchSet</code>. You then use <a>UpdateByteMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>ByteMatchSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>BadBot</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateByteMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594055.validator(path, query, header, formData, body)
  let scheme = call_594055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594055.url(scheme.get, call_594055.host, call_594055.base,
                         call_594055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594055, url, valid)

proc call*(call_594056: Call_CreateByteMatchSet_594043; body: JsonNode): Recallable =
  ## createByteMatchSet
  ## <p>Creates a <code>ByteMatchSet</code>. You then use <a>UpdateByteMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>ByteMatchSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>BadBot</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateByteMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateByteMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594057 = newJObject()
  if body != nil:
    body_594057 = body
  result = call_594056.call(nil, nil, nil, nil, body_594057)

var createByteMatchSet* = Call_CreateByteMatchSet_594043(
    name: "createByteMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateByteMatchSet",
    validator: validate_CreateByteMatchSet_594044, base: "/",
    url: url_CreateByteMatchSet_594045, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGeoMatchSet_594058 = ref object of OpenApiRestCall_593437
proc url_CreateGeoMatchSet_594060(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateGeoMatchSet_594059(path: JsonNode; query: JsonNode;
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
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594063 = header.getOrDefault("X-Amz-Target")
  valid_594063 = validateParameter(valid_594063, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateGeoMatchSet"))
  if valid_594063 != nil:
    section.add "X-Amz-Target", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Content-Sha256", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Algorithm")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Algorithm", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-Signature")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-Signature", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-SignedHeaders", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Credential")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Credential", valid_594068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594070: Call_CreateGeoMatchSet_594058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a>GeoMatchSet</a>, which you use to specify which web requests you want to allow or block based on the country that the requests originate from. For example, if you're receiving a lot of requests from one or more countries and you want to block the requests, you can create an <code>GeoMatchSet</code> that contains those countries and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSetSet</code> request to specify the countries that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594070.validator(path, query, header, formData, body)
  let scheme = call_594070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594070.url(scheme.get, call_594070.host, call_594070.base,
                         call_594070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594070, url, valid)

proc call*(call_594071: Call_CreateGeoMatchSet_594058; body: JsonNode): Recallable =
  ## createGeoMatchSet
  ## <p>Creates an <a>GeoMatchSet</a>, which you use to specify which web requests you want to allow or block based on the country that the requests originate from. For example, if you're receiving a lot of requests from one or more countries and you want to block the requests, you can create an <code>GeoMatchSet</code> that contains those countries and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateGeoMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSetSet</code> request to specify the countries that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594072 = newJObject()
  if body != nil:
    body_594072 = body
  result = call_594071.call(nil, nil, nil, nil, body_594072)

var createGeoMatchSet* = Call_CreateGeoMatchSet_594058(name: "createGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateGeoMatchSet",
    validator: validate_CreateGeoMatchSet_594059, base: "/",
    url: url_CreateGeoMatchSet_594060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIPSet_594073 = ref object of OpenApiRestCall_593437
proc url_CreateIPSet_594075(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateIPSet_594074(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594076 = header.getOrDefault("X-Amz-Date")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Date", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Security-Token")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Security-Token", valid_594077
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594078 = header.getOrDefault("X-Amz-Target")
  valid_594078 = validateParameter(valid_594078, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateIPSet"))
  if valid_594078 != nil:
    section.add "X-Amz-Target", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Content-Sha256", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Algorithm")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Algorithm", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Signature")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Signature", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-Credential")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Credential", valid_594083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_CreateIPSet_594073; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a>IPSet</a>, which you use to specify which web requests that you want to allow or block based on the IP addresses that the requests originate from. For example, if you're receiving a lot of requests from one or more individual IP addresses or one or more ranges of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that contains those IP addresses and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateIPSet</code> request.</p> </li> <li> <p>Submit a <code>CreateIPSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_CreateIPSet_594073; body: JsonNode): Recallable =
  ## createIPSet
  ## <p>Creates an <a>IPSet</a>, which you use to specify which web requests that you want to allow or block based on the IP addresses that the requests originate from. For example, if you're receiving a lot of requests from one or more individual IP addresses or one or more ranges of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that contains those IP addresses and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateIPSet</code> request.</p> </li> <li> <p>Submit a <code>CreateIPSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594087 = newJObject()
  if body != nil:
    body_594087 = body
  result = call_594086.call(nil, nil, nil, nil, body_594087)

var createIPSet* = Call_CreateIPSet_594073(name: "createIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateIPSet",
                                        validator: validate_CreateIPSet_594074,
                                        base: "/", url: url_CreateIPSet_594075,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRateBasedRule_594088 = ref object of OpenApiRestCall_593437
proc url_CreateRateBasedRule_594090(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRateBasedRule_594089(path: JsonNode; query: JsonNode;
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
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594093 = header.getOrDefault("X-Amz-Target")
  valid_594093 = validateParameter(valid_594093, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRateBasedRule"))
  if valid_594093 != nil:
    section.add "X-Amz-Target", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Content-Sha256", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Algorithm")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Algorithm", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Signature")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Signature", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  var valid_594098 = header.getOrDefault("X-Amz-Credential")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Credential", valid_594098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594100: Call_CreateRateBasedRule_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>RateBasedRule</a>. The <code>RateBasedRule</code> contains a <code>RateLimit</code>, which specifies the maximum number of requests that AWS WAF allows from a specified IP address in a five-minute period. The <code>RateBasedRule</code> also contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to count or block if these requests exceed the <code>RateLimit</code>.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request not only must exceed the <code>RateLimit</code>, but it also must match all the specifications to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that meet the conditions in the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions must be received at a rate of more than 15,000 requests every five minutes. If both conditions are met and the rate is exceeded, AWS WAF blocks the requests. If the rate drops below 15,000 for a five-minute period, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p> <p>To create and configure a <code>RateBasedRule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the rule. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRateBasedRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRateBasedRule</code> request to specify the predicates that you want to include in the rule.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RateBasedRule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594100.validator(path, query, header, formData, body)
  let scheme = call_594100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594100.url(scheme.get, call_594100.host, call_594100.base,
                         call_594100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594100, url, valid)

proc call*(call_594101: Call_CreateRateBasedRule_594088; body: JsonNode): Recallable =
  ## createRateBasedRule
  ## <p>Creates a <a>RateBasedRule</a>. The <code>RateBasedRule</code> contains a <code>RateLimit</code>, which specifies the maximum number of requests that AWS WAF allows from a specified IP address in a five-minute period. The <code>RateBasedRule</code> also contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to count or block if these requests exceed the <code>RateLimit</code>.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request not only must exceed the <code>RateLimit</code>, but it also must match all the specifications to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that meet the conditions in the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions must be received at a rate of more than 15,000 requests every five minutes. If both conditions are met and the rate is exceeded, AWS WAF blocks the requests. If the rate drops below 15,000 for a five-minute period, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p> <p>To create and configure a <code>RateBasedRule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the rule. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRateBasedRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRateBasedRule</code> request to specify the predicates that you want to include in the rule.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RateBasedRule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594102 = newJObject()
  if body != nil:
    body_594102 = body
  result = call_594101.call(nil, nil, nil, nil, body_594102)

var createRateBasedRule* = Call_CreateRateBasedRule_594088(
    name: "createRateBasedRule", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRateBasedRule",
    validator: validate_CreateRateBasedRule_594089, base: "/",
    url: url_CreateRateBasedRule_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegexMatchSet_594103 = ref object of OpenApiRestCall_593437
proc url_CreateRegexMatchSet_594105(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRegexMatchSet_594104(path: JsonNode; query: JsonNode;
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
  var valid_594106 = header.getOrDefault("X-Amz-Date")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Date", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Security-Token")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Security-Token", valid_594107
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594108 = header.getOrDefault("X-Amz-Target")
  valid_594108 = validateParameter(valid_594108, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRegexMatchSet"))
  if valid_594108 != nil:
    section.add "X-Amz-Target", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Content-Sha256", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Algorithm")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Algorithm", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Signature")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Signature", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-SignedHeaders", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Credential")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Credential", valid_594113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_CreateRegexMatchSet_594103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>RegexMatchSet</a>. You then use <a>UpdateRegexMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>RegexMatchSet</code> that contains a <code>RegexMatchTuple</code> that looks for any requests with <code>User-Agent</code> headers that match a <code>RegexPatternSet</code> with pattern <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value, using a <code>RegexPatternSet</code>, that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_CreateRegexMatchSet_594103; body: JsonNode): Recallable =
  ## createRegexMatchSet
  ## <p>Creates a <a>RegexMatchSet</a>. You then use <a>UpdateRegexMatchSet</a> to identify the part of a web request that you want AWS WAF to inspect, such as the values of the <code>User-Agent</code> header or the query string. For example, you can create a <code>RegexMatchSet</code> that contains a <code>RegexMatchTuple</code> that looks for any requests with <code>User-Agent</code> headers that match a <code>RegexPatternSet</code> with pattern <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexMatchSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value, using a <code>RegexPatternSet</code>, that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594117 = newJObject()
  if body != nil:
    body_594117 = body
  result = call_594116.call(nil, nil, nil, nil, body_594117)

var createRegexMatchSet* = Call_CreateRegexMatchSet_594103(
    name: "createRegexMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRegexMatchSet",
    validator: validate_CreateRegexMatchSet_594104, base: "/",
    url: url_CreateRegexMatchSet_594105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRegexPatternSet_594118 = ref object of OpenApiRestCall_593437
proc url_CreateRegexPatternSet_594120(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRegexPatternSet_594119(path: JsonNode; query: JsonNode;
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
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594123 = header.getOrDefault("X-Amz-Target")
  valid_594123 = validateParameter(valid_594123, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRegexPatternSet"))
  if valid_594123 != nil:
    section.add "X-Amz-Target", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Content-Sha256", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Algorithm")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Algorithm", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Signature")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Signature", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-SignedHeaders", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Credential")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Credential", valid_594128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594130: Call_CreateRegexPatternSet_594118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>RegexPatternSet</code>. You then use <a>UpdateRegexPatternSet</a> to specify the regular expression (regex) pattern that you want AWS WAF to search for, such as <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexPatternSet</a> request to specify the string that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594130.validator(path, query, header, formData, body)
  let scheme = call_594130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594130.url(scheme.get, call_594130.host, call_594130.base,
                         call_594130.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594130, url, valid)

proc call*(call_594131: Call_CreateRegexPatternSet_594118; body: JsonNode): Recallable =
  ## createRegexPatternSet
  ## <p>Creates a <code>RegexPatternSet</code>. You then use <a>UpdateRegexPatternSet</a> to specify the regular expression (regex) pattern that you want AWS WAF to search for, such as <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Submit a <code>CreateRegexPatternSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateRegexPatternSet</a> request to specify the string that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594132 = newJObject()
  if body != nil:
    body_594132 = body
  result = call_594131.call(nil, nil, nil, nil, body_594132)

var createRegexPatternSet* = Call_CreateRegexPatternSet_594118(
    name: "createRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRegexPatternSet",
    validator: validate_CreateRegexPatternSet_594119, base: "/",
    url: url_CreateRegexPatternSet_594120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRule_594133 = ref object of OpenApiRestCall_593437
proc url_CreateRule_594135(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRule_594134(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594136 = header.getOrDefault("X-Amz-Date")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Date", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Security-Token")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Security-Token", valid_594137
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594138 = header.getOrDefault("X-Amz-Target")
  valid_594138 = validateParameter(valid_594138, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRule"))
  if valid_594138 != nil:
    section.add "X-Amz-Target", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-Content-Sha256", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Algorithm")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Algorithm", valid_594140
  var valid_594141 = header.getOrDefault("X-Amz-Signature")
  valid_594141 = validateParameter(valid_594141, JString, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "X-Amz-Signature", valid_594141
  var valid_594142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594142 = validateParameter(valid_594142, JString, required = false,
                                 default = nil)
  if valid_594142 != nil:
    section.add "X-Amz-SignedHeaders", valid_594142
  var valid_594143 = header.getOrDefault("X-Amz-Credential")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Credential", valid_594143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594145: Call_CreateRule_594133; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>Rule</code>, which contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to block. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed or blocked. For example, suppose that you add the following to a <code>Rule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to blocks requests that satisfy the <code>Rule</code>. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to specify the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594145.validator(path, query, header, formData, body)
  let scheme = call_594145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594145.url(scheme.get, call_594145.host, call_594145.base,
                         call_594145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594145, url, valid)

proc call*(call_594146: Call_CreateRule_594133; body: JsonNode): Recallable =
  ## createRule
  ## <p>Creates a <code>Rule</code>, which contains the <code>IPSet</code> objects, <code>ByteMatchSet</code> objects, and other predicates that identify the requests that you want to block. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed or blocked. For example, suppose that you add the following to a <code>Rule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to blocks requests that satisfy the <code>Rule</code>. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>. For more information, see <a>CreateByteMatchSet</a>, <a>CreateIPSet</a>, and <a>CreateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateRule</code> request.</p> </li> <li> <p>Submit a <code>CreateRule</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to specify the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. For more information, see <a>CreateWebACL</a>.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594147 = newJObject()
  if body != nil:
    body_594147 = body
  result = call_594146.call(nil, nil, nil, nil, body_594147)

var createRule* = Call_CreateRule_594133(name: "createRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRule",
                                      validator: validate_CreateRule_594134,
                                      base: "/", url: url_CreateRule_594135,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRuleGroup_594148 = ref object of OpenApiRestCall_593437
proc url_CreateRuleGroup_594150(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRuleGroup_594149(path: JsonNode; query: JsonNode;
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
  var valid_594151 = header.getOrDefault("X-Amz-Date")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Date", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Security-Token")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Security-Token", valid_594152
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594153 = header.getOrDefault("X-Amz-Target")
  valid_594153 = validateParameter(valid_594153, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateRuleGroup"))
  if valid_594153 != nil:
    section.add "X-Amz-Target", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Content-Sha256", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Algorithm")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Algorithm", valid_594155
  var valid_594156 = header.getOrDefault("X-Amz-Signature")
  valid_594156 = validateParameter(valid_594156, JString, required = false,
                                 default = nil)
  if valid_594156 != nil:
    section.add "X-Amz-Signature", valid_594156
  var valid_594157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594157 = validateParameter(valid_594157, JString, required = false,
                                 default = nil)
  if valid_594157 != nil:
    section.add "X-Amz-SignedHeaders", valid_594157
  var valid_594158 = header.getOrDefault("X-Amz-Credential")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Credential", valid_594158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594160: Call_CreateRuleGroup_594148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>RuleGroup</code>. A rule group is a collection of predefined rules that you add to a web ACL. You use <a>UpdateRuleGroup</a> to add rules to the rule group.</p> <p>Rule groups are subject to the following limits:</p> <ul> <li> <p>Three rule groups per account. You can request an increase to this limit by contacting customer support.</p> </li> <li> <p>One rule group per web ACL.</p> </li> <li> <p>Ten rules per rule group.</p> </li> </ul> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594160.validator(path, query, header, formData, body)
  let scheme = call_594160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594160.url(scheme.get, call_594160.host, call_594160.base,
                         call_594160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594160, url, valid)

proc call*(call_594161: Call_CreateRuleGroup_594148; body: JsonNode): Recallable =
  ## createRuleGroup
  ## <p>Creates a <code>RuleGroup</code>. A rule group is a collection of predefined rules that you add to a web ACL. You use <a>UpdateRuleGroup</a> to add rules to the rule group.</p> <p>Rule groups are subject to the following limits:</p> <ul> <li> <p>Three rule groups per account. You can request an increase to this limit by contacting customer support.</p> </li> <li> <p>One rule group per web ACL.</p> </li> <li> <p>Ten rules per rule group.</p> </li> </ul> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594162 = newJObject()
  if body != nil:
    body_594162 = body
  result = call_594161.call(nil, nil, nil, nil, body_594162)

var createRuleGroup* = Call_CreateRuleGroup_594148(name: "createRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateRuleGroup",
    validator: validate_CreateRuleGroup_594149, base: "/", url: url_CreateRuleGroup_594150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSizeConstraintSet_594163 = ref object of OpenApiRestCall_593437
proc url_CreateSizeConstraintSet_594165(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSizeConstraintSet_594164(path: JsonNode; query: JsonNode;
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
  var valid_594166 = header.getOrDefault("X-Amz-Date")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Date", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Security-Token")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Security-Token", valid_594167
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594168 = header.getOrDefault("X-Amz-Target")
  valid_594168 = validateParameter(valid_594168, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateSizeConstraintSet"))
  if valid_594168 != nil:
    section.add "X-Amz-Target", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Content-Sha256", valid_594169
  var valid_594170 = header.getOrDefault("X-Amz-Algorithm")
  valid_594170 = validateParameter(valid_594170, JString, required = false,
                                 default = nil)
  if valid_594170 != nil:
    section.add "X-Amz-Algorithm", valid_594170
  var valid_594171 = header.getOrDefault("X-Amz-Signature")
  valid_594171 = validateParameter(valid_594171, JString, required = false,
                                 default = nil)
  if valid_594171 != nil:
    section.add "X-Amz-Signature", valid_594171
  var valid_594172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594172 = validateParameter(valid_594172, JString, required = false,
                                 default = nil)
  if valid_594172 != nil:
    section.add "X-Amz-SignedHeaders", valid_594172
  var valid_594173 = header.getOrDefault("X-Amz-Credential")
  valid_594173 = validateParameter(valid_594173, JString, required = false,
                                 default = nil)
  if valid_594173 != nil:
    section.add "X-Amz-Credential", valid_594173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594175: Call_CreateSizeConstraintSet_594163; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>SizeConstraintSet</code>. You then use <a>UpdateSizeConstraintSet</a> to identify the part of a web request that you want AWS WAF to check for length, such as the length of the <code>User-Agent</code> header or the length of the query string. For example, you can create a <code>SizeConstraintSet</code> that matches any requests that have a query string that is longer than 100 bytes. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateSizeConstraintSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594175.validator(path, query, header, formData, body)
  let scheme = call_594175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594175.url(scheme.get, call_594175.host, call_594175.base,
                         call_594175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594175, url, valid)

proc call*(call_594176: Call_CreateSizeConstraintSet_594163; body: JsonNode): Recallable =
  ## createSizeConstraintSet
  ## <p>Creates a <code>SizeConstraintSet</code>. You then use <a>UpdateSizeConstraintSet</a> to identify the part of a web request that you want AWS WAF to check for length, such as the length of the <code>User-Agent</code> header or the length of the query string. For example, you can create a <code>SizeConstraintSet</code> that matches any requests that have a query string that is longer than 100 bytes. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSizeConstraintSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <a>UpdateSizeConstraintSet</a> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594177 = newJObject()
  if body != nil:
    body_594177 = body
  result = call_594176.call(nil, nil, nil, nil, body_594177)

var createSizeConstraintSet* = Call_CreateSizeConstraintSet_594163(
    name: "createSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateSizeConstraintSet",
    validator: validate_CreateSizeConstraintSet_594164, base: "/",
    url: url_CreateSizeConstraintSet_594165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSqlInjectionMatchSet_594178 = ref object of OpenApiRestCall_593437
proc url_CreateSqlInjectionMatchSet_594180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSqlInjectionMatchSet_594179(path: JsonNode; query: JsonNode;
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
  var valid_594181 = header.getOrDefault("X-Amz-Date")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Date", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594183 = header.getOrDefault("X-Amz-Target")
  valid_594183 = validateParameter(valid_594183, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateSqlInjectionMatchSet"))
  if valid_594183 != nil:
    section.add "X-Amz-Target", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594190: Call_CreateSqlInjectionMatchSet_594178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a>SqlInjectionMatchSet</a>, which you use to allow, block, or count requests that contain snippets of SQL code in a specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateSqlInjectionMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count malicious SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594190.validator(path, query, header, formData, body)
  let scheme = call_594190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594190.url(scheme.get, call_594190.host, call_594190.base,
                         call_594190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594190, url, valid)

proc call*(call_594191: Call_CreateSqlInjectionMatchSet_594178; body: JsonNode): Recallable =
  ## createSqlInjectionMatchSet
  ## <p>Creates a <a>SqlInjectionMatchSet</a>, which you use to allow, block, or count requests that contain snippets of SQL code in a specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateSqlInjectionMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count malicious SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594192 = newJObject()
  if body != nil:
    body_594192 = body
  result = call_594191.call(nil, nil, nil, nil, body_594192)

var createSqlInjectionMatchSet* = Call_CreateSqlInjectionMatchSet_594178(
    name: "createSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateSqlInjectionMatchSet",
    validator: validate_CreateSqlInjectionMatchSet_594179, base: "/",
    url: url_CreateSqlInjectionMatchSet_594180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateWebACL_594193 = ref object of OpenApiRestCall_593437
proc url_CreateWebACL_594195(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateWebACL_594194(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594196 = header.getOrDefault("X-Amz-Date")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Date", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594198 = header.getOrDefault("X-Amz-Target")
  valid_594198 = validateParameter(valid_594198, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateWebACL"))
  if valid_594198 != nil:
    section.add "X-Amz-Target", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594205: Call_CreateWebACL_594193; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <code>WebACL</code>, which contains the <code>Rules</code> that identify the CloudFront web requests that you want to allow, block, or count. AWS WAF evaluates <code>Rules</code> in order based on the value of <code>Priority</code> for each <code>Rule</code>.</p> <p>You also specify a default action, either <code>ALLOW</code> or <code>BLOCK</code>. If a web request doesn't match any of the <code>Rules</code> in a <code>WebACL</code>, AWS WAF responds to the request with the default action. </p> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>ByteMatchSet</code> objects and other predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateWebACL</code> request.</p> </li> <li> <p>Submit a <code>CreateWebACL</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <a>UpdateWebACL</a> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution.</p> </li> </ol> <p>For more information about how to use the AWS WAF API, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594205.validator(path, query, header, formData, body)
  let scheme = call_594205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594205.url(scheme.get, call_594205.host, call_594205.base,
                         call_594205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594205, url, valid)

proc call*(call_594206: Call_CreateWebACL_594193; body: JsonNode): Recallable =
  ## createWebACL
  ## <p>Creates a <code>WebACL</code>, which contains the <code>Rules</code> that identify the CloudFront web requests that you want to allow, block, or count. AWS WAF evaluates <code>Rules</code> in order based on the value of <code>Priority</code> for each <code>Rule</code>.</p> <p>You also specify a default action, either <code>ALLOW</code> or <code>BLOCK</code>. If a web request doesn't match any of the <code>Rules</code> in a <code>WebACL</code>, AWS WAF responds to the request with the default action. </p> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>ByteMatchSet</code> objects and other predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateWebACL</code> request.</p> </li> <li> <p>Submit a <code>CreateWebACL</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <a>UpdateWebACL</a> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution.</p> </li> </ol> <p>For more information about how to use the AWS WAF API, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594207 = newJObject()
  if body != nil:
    body_594207 = body
  result = call_594206.call(nil, nil, nil, nil, body_594207)

var createWebACL* = Call_CreateWebACL_594193(name: "createWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateWebACL",
    validator: validate_CreateWebACL_594194, base: "/", url: url_CreateWebACL_594195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateXssMatchSet_594208 = ref object of OpenApiRestCall_593437
proc url_CreateXssMatchSet_594210(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateXssMatchSet_594209(path: JsonNode; query: JsonNode;
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
  var valid_594211 = header.getOrDefault("X-Amz-Date")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Date", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Security-Token")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Security-Token", valid_594212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594213 = header.getOrDefault("X-Amz-Target")
  valid_594213 = validateParameter(valid_594213, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.CreateXssMatchSet"))
  if valid_594213 != nil:
    section.add "X-Amz-Target", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Content-Sha256", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Algorithm")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Algorithm", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Signature")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Signature", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-SignedHeaders", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Credential")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Credential", valid_594218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594220: Call_CreateXssMatchSet_594208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a>XssMatchSet</a>, which you use to allow, block, or count requests that contain cross-site scripting attacks in the specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateXssMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateXssMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_594220.validator(path, query, header, formData, body)
  let scheme = call_594220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594220.url(scheme.get, call_594220.host, call_594220.base,
                         call_594220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594220, url, valid)

proc call*(call_594221: Call_CreateXssMatchSet_594208; body: JsonNode): Recallable =
  ## createXssMatchSet
  ## <p>Creates an <a>XssMatchSet</a>, which you use to allow, block, or count requests that contain cross-site scripting attacks in the specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings.</p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>CreateXssMatchSet</code> request.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateXssMatchSet</a> request.</p> </li> <li> <p>Submit an <a>UpdateXssMatchSet</a> request to specify the parts of web requests in which you want to allow, block, or count cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_594222 = newJObject()
  if body != nil:
    body_594222 = body
  result = call_594221.call(nil, nil, nil, nil, body_594222)

var createXssMatchSet* = Call_CreateXssMatchSet_594208(name: "createXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.CreateXssMatchSet",
    validator: validate_CreateXssMatchSet_594209, base: "/",
    url: url_CreateXssMatchSet_594210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteByteMatchSet_594223 = ref object of OpenApiRestCall_593437
proc url_DeleteByteMatchSet_594225(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteByteMatchSet_594224(path: JsonNode; query: JsonNode;
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
  var valid_594226 = header.getOrDefault("X-Amz-Date")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Date", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Security-Token")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Security-Token", valid_594227
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594228 = header.getOrDefault("X-Amz-Target")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteByteMatchSet"))
  if valid_594228 != nil:
    section.add "X-Amz-Target", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Content-Sha256", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Algorithm")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Algorithm", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Signature")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Signature", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-SignedHeaders", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Credential")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Credential", valid_594233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594235: Call_DeleteByteMatchSet_594223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>ByteMatchSet</a>. You can't delete a <code>ByteMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>ByteMatchTuple</a> objects (any filters).</p> <p>If you just want to remove a <code>ByteMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>ByteMatchSet</code> to remove filters, if any. For more information, see <a>UpdateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteByteMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_594235.validator(path, query, header, formData, body)
  let scheme = call_594235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594235.url(scheme.get, call_594235.host, call_594235.base,
                         call_594235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594235, url, valid)

proc call*(call_594236: Call_DeleteByteMatchSet_594223; body: JsonNode): Recallable =
  ## deleteByteMatchSet
  ## <p>Permanently deletes a <a>ByteMatchSet</a>. You can't delete a <code>ByteMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>ByteMatchTuple</a> objects (any filters).</p> <p>If you just want to remove a <code>ByteMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>ByteMatchSet</code> to remove filters, if any. For more information, see <a>UpdateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteByteMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteByteMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594237 = newJObject()
  if body != nil:
    body_594237 = body
  result = call_594236.call(nil, nil, nil, nil, body_594237)

var deleteByteMatchSet* = Call_DeleteByteMatchSet_594223(
    name: "deleteByteMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteByteMatchSet",
    validator: validate_DeleteByteMatchSet_594224, base: "/",
    url: url_DeleteByteMatchSet_594225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGeoMatchSet_594238 = ref object of OpenApiRestCall_593437
proc url_DeleteGeoMatchSet_594240(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteGeoMatchSet_594239(path: JsonNode; query: JsonNode;
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
  var valid_594241 = header.getOrDefault("X-Amz-Date")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Date", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Security-Token")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Security-Token", valid_594242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594243 = header.getOrDefault("X-Amz-Target")
  valid_594243 = validateParameter(valid_594243, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteGeoMatchSet"))
  if valid_594243 != nil:
    section.add "X-Amz-Target", valid_594243
  var valid_594244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594244 = validateParameter(valid_594244, JString, required = false,
                                 default = nil)
  if valid_594244 != nil:
    section.add "X-Amz-Content-Sha256", valid_594244
  var valid_594245 = header.getOrDefault("X-Amz-Algorithm")
  valid_594245 = validateParameter(valid_594245, JString, required = false,
                                 default = nil)
  if valid_594245 != nil:
    section.add "X-Amz-Algorithm", valid_594245
  var valid_594246 = header.getOrDefault("X-Amz-Signature")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "X-Amz-Signature", valid_594246
  var valid_594247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594247 = validateParameter(valid_594247, JString, required = false,
                                 default = nil)
  if valid_594247 != nil:
    section.add "X-Amz-SignedHeaders", valid_594247
  var valid_594248 = header.getOrDefault("X-Amz-Credential")
  valid_594248 = validateParameter(valid_594248, JString, required = false,
                                 default = nil)
  if valid_594248 != nil:
    section.add "X-Amz-Credential", valid_594248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594250: Call_DeleteGeoMatchSet_594238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>GeoMatchSet</a>. You can't delete a <code>GeoMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any countries.</p> <p>If you just want to remove a <code>GeoMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>GeoMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>GeoMatchSet</code> to remove any countries. For more information, see <a>UpdateGeoMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteGeoMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_594250.validator(path, query, header, formData, body)
  let scheme = call_594250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594250.url(scheme.get, call_594250.host, call_594250.base,
                         call_594250.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594250, url, valid)

proc call*(call_594251: Call_DeleteGeoMatchSet_594238; body: JsonNode): Recallable =
  ## deleteGeoMatchSet
  ## <p>Permanently deletes a <a>GeoMatchSet</a>. You can't delete a <code>GeoMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any countries.</p> <p>If you just want to remove a <code>GeoMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>GeoMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>GeoMatchSet</code> to remove any countries. For more information, see <a>UpdateGeoMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteGeoMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteGeoMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594252 = newJObject()
  if body != nil:
    body_594252 = body
  result = call_594251.call(nil, nil, nil, nil, body_594252)

var deleteGeoMatchSet* = Call_DeleteGeoMatchSet_594238(name: "deleteGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteGeoMatchSet",
    validator: validate_DeleteGeoMatchSet_594239, base: "/",
    url: url_DeleteGeoMatchSet_594240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIPSet_594253 = ref object of OpenApiRestCall_593437
proc url_DeleteIPSet_594255(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteIPSet_594254(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594256 = header.getOrDefault("X-Amz-Date")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Date", valid_594256
  var valid_594257 = header.getOrDefault("X-Amz-Security-Token")
  valid_594257 = validateParameter(valid_594257, JString, required = false,
                                 default = nil)
  if valid_594257 != nil:
    section.add "X-Amz-Security-Token", valid_594257
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594258 = header.getOrDefault("X-Amz-Target")
  valid_594258 = validateParameter(valid_594258, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteIPSet"))
  if valid_594258 != nil:
    section.add "X-Amz-Target", valid_594258
  var valid_594259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "X-Amz-Content-Sha256", valid_594259
  var valid_594260 = header.getOrDefault("X-Amz-Algorithm")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "X-Amz-Algorithm", valid_594260
  var valid_594261 = header.getOrDefault("X-Amz-Signature")
  valid_594261 = validateParameter(valid_594261, JString, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "X-Amz-Signature", valid_594261
  var valid_594262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594262 = validateParameter(valid_594262, JString, required = false,
                                 default = nil)
  if valid_594262 != nil:
    section.add "X-Amz-SignedHeaders", valid_594262
  var valid_594263 = header.getOrDefault("X-Amz-Credential")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Credential", valid_594263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594265: Call_DeleteIPSet_594253; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes an <a>IPSet</a>. You can't delete an <code>IPSet</code> if it's still used in any <code>Rules</code> or if it still includes any IP addresses.</p> <p>If you just want to remove an <code>IPSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>IPSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>IPSet</code> to remove IP address ranges, if any. For more information, see <a>UpdateIPSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteIPSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteIPSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_594265.validator(path, query, header, formData, body)
  let scheme = call_594265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594265.url(scheme.get, call_594265.host, call_594265.base,
                         call_594265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594265, url, valid)

proc call*(call_594266: Call_DeleteIPSet_594253; body: JsonNode): Recallable =
  ## deleteIPSet
  ## <p>Permanently deletes an <a>IPSet</a>. You can't delete an <code>IPSet</code> if it's still used in any <code>Rules</code> or if it still includes any IP addresses.</p> <p>If you just want to remove an <code>IPSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>IPSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>IPSet</code> to remove IP address ranges, if any. For more information, see <a>UpdateIPSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteIPSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteIPSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594267 = newJObject()
  if body != nil:
    body_594267 = body
  result = call_594266.call(nil, nil, nil, nil, body_594267)

var deleteIPSet* = Call_DeleteIPSet_594253(name: "deleteIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteIPSet",
                                        validator: validate_DeleteIPSet_594254,
                                        base: "/", url: url_DeleteIPSet_594255,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLoggingConfiguration_594268 = ref object of OpenApiRestCall_593437
proc url_DeleteLoggingConfiguration_594270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteLoggingConfiguration_594269(path: JsonNode; query: JsonNode;
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
  var valid_594271 = header.getOrDefault("X-Amz-Date")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Date", valid_594271
  var valid_594272 = header.getOrDefault("X-Amz-Security-Token")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "X-Amz-Security-Token", valid_594272
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594273 = header.getOrDefault("X-Amz-Target")
  valid_594273 = validateParameter(valid_594273, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteLoggingConfiguration"))
  if valid_594273 != nil:
    section.add "X-Amz-Target", valid_594273
  var valid_594274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594274 = validateParameter(valid_594274, JString, required = false,
                                 default = nil)
  if valid_594274 != nil:
    section.add "X-Amz-Content-Sha256", valid_594274
  var valid_594275 = header.getOrDefault("X-Amz-Algorithm")
  valid_594275 = validateParameter(valid_594275, JString, required = false,
                                 default = nil)
  if valid_594275 != nil:
    section.add "X-Amz-Algorithm", valid_594275
  var valid_594276 = header.getOrDefault("X-Amz-Signature")
  valid_594276 = validateParameter(valid_594276, JString, required = false,
                                 default = nil)
  if valid_594276 != nil:
    section.add "X-Amz-Signature", valid_594276
  var valid_594277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-SignedHeaders", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Credential")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Credential", valid_594278
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594280: Call_DeleteLoggingConfiguration_594268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the <a>LoggingConfiguration</a> from the specified web ACL.
  ## 
  let valid = call_594280.validator(path, query, header, formData, body)
  let scheme = call_594280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594280.url(scheme.get, call_594280.host, call_594280.base,
                         call_594280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594280, url, valid)

proc call*(call_594281: Call_DeleteLoggingConfiguration_594268; body: JsonNode): Recallable =
  ## deleteLoggingConfiguration
  ## Permanently deletes the <a>LoggingConfiguration</a> from the specified web ACL.
  ##   body: JObject (required)
  var body_594282 = newJObject()
  if body != nil:
    body_594282 = body
  result = call_594281.call(nil, nil, nil, nil, body_594282)

var deleteLoggingConfiguration* = Call_DeleteLoggingConfiguration_594268(
    name: "deleteLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteLoggingConfiguration",
    validator: validate_DeleteLoggingConfiguration_594269, base: "/",
    url: url_DeleteLoggingConfiguration_594270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePermissionPolicy_594283 = ref object of OpenApiRestCall_593437
proc url_DeletePermissionPolicy_594285(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePermissionPolicy_594284(path: JsonNode; query: JsonNode;
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
  var valid_594286 = header.getOrDefault("X-Amz-Date")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Date", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Security-Token")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Security-Token", valid_594287
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594288 = header.getOrDefault("X-Amz-Target")
  valid_594288 = validateParameter(valid_594288, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeletePermissionPolicy"))
  if valid_594288 != nil:
    section.add "X-Amz-Target", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Content-Sha256", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Algorithm")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Algorithm", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Signature")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Signature", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Credential")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Credential", valid_594293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594295: Call_DeletePermissionPolicy_594283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes an IAM policy from the specified RuleGroup.</p> <p>The user making the request must be the owner of the RuleGroup.</p>
  ## 
  let valid = call_594295.validator(path, query, header, formData, body)
  let scheme = call_594295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594295.url(scheme.get, call_594295.host, call_594295.base,
                         call_594295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594295, url, valid)

proc call*(call_594296: Call_DeletePermissionPolicy_594283; body: JsonNode): Recallable =
  ## deletePermissionPolicy
  ## <p>Permanently deletes an IAM policy from the specified RuleGroup.</p> <p>The user making the request must be the owner of the RuleGroup.</p>
  ##   body: JObject (required)
  var body_594297 = newJObject()
  if body != nil:
    body_594297 = body
  result = call_594296.call(nil, nil, nil, nil, body_594297)

var deletePermissionPolicy* = Call_DeletePermissionPolicy_594283(
    name: "deletePermissionPolicy", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeletePermissionPolicy",
    validator: validate_DeletePermissionPolicy_594284, base: "/",
    url: url_DeletePermissionPolicy_594285, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRateBasedRule_594298 = ref object of OpenApiRestCall_593437
proc url_DeleteRateBasedRule_594300(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRateBasedRule_594299(path: JsonNode; query: JsonNode;
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
  var valid_594301 = header.getOrDefault("X-Amz-Date")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Date", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Security-Token")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Security-Token", valid_594302
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594303 = header.getOrDefault("X-Amz-Target")
  valid_594303 = validateParameter(valid_594303, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRateBasedRule"))
  if valid_594303 != nil:
    section.add "X-Amz-Target", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Content-Sha256", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Algorithm")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Algorithm", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Signature")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Signature", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Credential")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Credential", valid_594308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594310: Call_DeleteRateBasedRule_594298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>RateBasedRule</a>. You can't delete a rule if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a rule from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RateBasedRule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RateBasedRule</code> to remove predicates, if any. For more information, see <a>UpdateRateBasedRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRateBasedRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRateBasedRule</code> request.</p> </li> </ol>
  ## 
  let valid = call_594310.validator(path, query, header, formData, body)
  let scheme = call_594310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594310.url(scheme.get, call_594310.host, call_594310.base,
                         call_594310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594310, url, valid)

proc call*(call_594311: Call_DeleteRateBasedRule_594298; body: JsonNode): Recallable =
  ## deleteRateBasedRule
  ## <p>Permanently deletes a <a>RateBasedRule</a>. You can't delete a rule if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a rule from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RateBasedRule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RateBasedRule</code> to remove predicates, if any. For more information, see <a>UpdateRateBasedRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRateBasedRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRateBasedRule</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594312 = newJObject()
  if body != nil:
    body_594312 = body
  result = call_594311.call(nil, nil, nil, nil, body_594312)

var deleteRateBasedRule* = Call_DeleteRateBasedRule_594298(
    name: "deleteRateBasedRule", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRateBasedRule",
    validator: validate_DeleteRateBasedRule_594299, base: "/",
    url: url_DeleteRateBasedRule_594300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegexMatchSet_594313 = ref object of OpenApiRestCall_593437
proc url_DeleteRegexMatchSet_594315(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRegexMatchSet_594314(path: JsonNode; query: JsonNode;
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
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Security-Token")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Security-Token", valid_594317
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594318 = header.getOrDefault("X-Amz-Target")
  valid_594318 = validateParameter(valid_594318, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRegexMatchSet"))
  if valid_594318 != nil:
    section.add "X-Amz-Target", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Content-Sha256", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Algorithm")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Algorithm", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Signature")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Signature", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-SignedHeaders", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-Credential")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-Credential", valid_594323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594325: Call_DeleteRegexMatchSet_594313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>RegexMatchSet</a>. You can't delete a <code>RegexMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <code>RegexMatchTuples</code> objects (any filters).</p> <p>If you just want to remove a <code>RegexMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>RegexMatchSet</code> to remove filters, if any. For more information, see <a>UpdateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteRegexMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_594325.validator(path, query, header, formData, body)
  let scheme = call_594325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594325.url(scheme.get, call_594325.host, call_594325.base,
                         call_594325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594325, url, valid)

proc call*(call_594326: Call_DeleteRegexMatchSet_594313; body: JsonNode): Recallable =
  ## deleteRegexMatchSet
  ## <p>Permanently deletes a <a>RegexMatchSet</a>. You can't delete a <code>RegexMatchSet</code> if it's still used in any <code>Rules</code> or if it still includes any <code>RegexMatchTuples</code> objects (any filters).</p> <p>If you just want to remove a <code>RegexMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>RegexMatchSet</code> to remove filters, if any. For more information, see <a>UpdateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRegexMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteRegexMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594327 = newJObject()
  if body != nil:
    body_594327 = body
  result = call_594326.call(nil, nil, nil, nil, body_594327)

var deleteRegexMatchSet* = Call_DeleteRegexMatchSet_594313(
    name: "deleteRegexMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRegexMatchSet",
    validator: validate_DeleteRegexMatchSet_594314, base: "/",
    url: url_DeleteRegexMatchSet_594315, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRegexPatternSet_594328 = ref object of OpenApiRestCall_593437
proc url_DeleteRegexPatternSet_594330(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRegexPatternSet_594329(path: JsonNode; query: JsonNode;
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
  var valid_594331 = header.getOrDefault("X-Amz-Date")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "X-Amz-Date", valid_594331
  var valid_594332 = header.getOrDefault("X-Amz-Security-Token")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "X-Amz-Security-Token", valid_594332
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594333 = header.getOrDefault("X-Amz-Target")
  valid_594333 = validateParameter(valid_594333, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRegexPatternSet"))
  if valid_594333 != nil:
    section.add "X-Amz-Target", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Content-Sha256", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Algorithm")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Algorithm", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Signature")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Signature", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-SignedHeaders", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-Credential")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Credential", valid_594338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_DeleteRegexPatternSet_594328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a <a>RegexPatternSet</a>. You can't delete a <code>RegexPatternSet</code> if it's still used in any <code>RegexMatchSet</code> or if the <code>RegexPatternSet</code> is not empty. 
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_DeleteRegexPatternSet_594328; body: JsonNode): Recallable =
  ## deleteRegexPatternSet
  ## Permanently deletes a <a>RegexPatternSet</a>. You can't delete a <code>RegexPatternSet</code> if it's still used in any <code>RegexMatchSet</code> or if the <code>RegexPatternSet</code> is not empty. 
  ##   body: JObject (required)
  var body_594342 = newJObject()
  if body != nil:
    body_594342 = body
  result = call_594341.call(nil, nil, nil, nil, body_594342)

var deleteRegexPatternSet* = Call_DeleteRegexPatternSet_594328(
    name: "deleteRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRegexPatternSet",
    validator: validate_DeleteRegexPatternSet_594329, base: "/",
    url: url_DeleteRegexPatternSet_594330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRule_594343 = ref object of OpenApiRestCall_593437
proc url_DeleteRule_594345(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRule_594344(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594346 = header.getOrDefault("X-Amz-Date")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "X-Amz-Date", valid_594346
  var valid_594347 = header.getOrDefault("X-Amz-Security-Token")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Security-Token", valid_594347
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594348 = header.getOrDefault("X-Amz-Target")
  valid_594348 = validateParameter(valid_594348, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRule"))
  if valid_594348 != nil:
    section.add "X-Amz-Target", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594355: Call_DeleteRule_594343; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>Rule</a>. You can't delete a <code>Rule</code> if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a <code>Rule</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>Rule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>Rule</code> to remove predicates, if any. For more information, see <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRule</code> request.</p> </li> </ol>
  ## 
  let valid = call_594355.validator(path, query, header, formData, body)
  let scheme = call_594355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594355.url(scheme.get, call_594355.host, call_594355.base,
                         call_594355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594355, url, valid)

proc call*(call_594356: Call_DeleteRule_594343; body: JsonNode): Recallable =
  ## deleteRule
  ## <p>Permanently deletes a <a>Rule</a>. You can't delete a <code>Rule</code> if it's still used in any <code>WebACL</code> objects or if it still includes any predicates, such as <code>ByteMatchSet</code> objects.</p> <p>If you just want to remove a <code>Rule</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>Rule</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>Rule</code> to remove predicates, if any. For more information, see <a>UpdateRule</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRule</code> request.</p> </li> <li> <p>Submit a <code>DeleteRule</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594357 = newJObject()
  if body != nil:
    body_594357 = body
  result = call_594356.call(nil, nil, nil, nil, body_594357)

var deleteRule* = Call_DeleteRule_594343(name: "deleteRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRule",
                                      validator: validate_DeleteRule_594344,
                                      base: "/", url: url_DeleteRule_594345,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRuleGroup_594358 = ref object of OpenApiRestCall_593437
proc url_DeleteRuleGroup_594360(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRuleGroup_594359(path: JsonNode; query: JsonNode;
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
  var valid_594361 = header.getOrDefault("X-Amz-Date")
  valid_594361 = validateParameter(valid_594361, JString, required = false,
                                 default = nil)
  if valid_594361 != nil:
    section.add "X-Amz-Date", valid_594361
  var valid_594362 = header.getOrDefault("X-Amz-Security-Token")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Security-Token", valid_594362
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594363 = header.getOrDefault("X-Amz-Target")
  valid_594363 = validateParameter(valid_594363, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteRuleGroup"))
  if valid_594363 != nil:
    section.add "X-Amz-Target", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Signature")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Signature", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Credential")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Credential", valid_594368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_DeleteRuleGroup_594358; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>RuleGroup</a>. You can't delete a <code>RuleGroup</code> if it's still used in any <code>WebACL</code> objects or if it still includes any rules.</p> <p>If you just want to remove a <code>RuleGroup</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RuleGroup</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RuleGroup</code> to remove rules, if any. For more information, see <a>UpdateRuleGroup</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRuleGroup</code> request.</p> </li> <li> <p>Submit a <code>DeleteRuleGroup</code> request.</p> </li> </ol>
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_DeleteRuleGroup_594358; body: JsonNode): Recallable =
  ## deleteRuleGroup
  ## <p>Permanently deletes a <a>RuleGroup</a>. You can't delete a <code>RuleGroup</code> if it's still used in any <code>WebACL</code> objects or if it still includes any rules.</p> <p>If you just want to remove a <code>RuleGroup</code> from a <code>WebACL</code>, use <a>UpdateWebACL</a>.</p> <p>To permanently delete a <code>RuleGroup</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>RuleGroup</code> to remove rules, if any. For more information, see <a>UpdateRuleGroup</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteRuleGroup</code> request.</p> </li> <li> <p>Submit a <code>DeleteRuleGroup</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594372 = newJObject()
  if body != nil:
    body_594372 = body
  result = call_594371.call(nil, nil, nil, nil, body_594372)

var deleteRuleGroup* = Call_DeleteRuleGroup_594358(name: "deleteRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteRuleGroup",
    validator: validate_DeleteRuleGroup_594359, base: "/", url: url_DeleteRuleGroup_594360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSizeConstraintSet_594373 = ref object of OpenApiRestCall_593437
proc url_DeleteSizeConstraintSet_594375(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSizeConstraintSet_594374(path: JsonNode; query: JsonNode;
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
  var valid_594376 = header.getOrDefault("X-Amz-Date")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "X-Amz-Date", valid_594376
  var valid_594377 = header.getOrDefault("X-Amz-Security-Token")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "X-Amz-Security-Token", valid_594377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594378 = header.getOrDefault("X-Amz-Target")
  valid_594378 = validateParameter(valid_594378, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteSizeConstraintSet"))
  if valid_594378 != nil:
    section.add "X-Amz-Target", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Algorithm")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Algorithm", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Signature")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Signature", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-SignedHeaders", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Credential")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Credential", valid_594383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594385: Call_DeleteSizeConstraintSet_594373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>SizeConstraintSet</a>. You can't delete a <code>SizeConstraintSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>SizeConstraint</a> objects (any filters).</p> <p>If you just want to remove a <code>SizeConstraintSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>SizeConstraintSet</code> to remove filters, if any. For more information, see <a>UpdateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSizeConstraintSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_594385.validator(path, query, header, formData, body)
  let scheme = call_594385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594385.url(scheme.get, call_594385.host, call_594385.base,
                         call_594385.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594385, url, valid)

proc call*(call_594386: Call_DeleteSizeConstraintSet_594373; body: JsonNode): Recallable =
  ## deleteSizeConstraintSet
  ## <p>Permanently deletes a <a>SizeConstraintSet</a>. You can't delete a <code>SizeConstraintSet</code> if it's still used in any <code>Rules</code> or if it still includes any <a>SizeConstraint</a> objects (any filters).</p> <p>If you just want to remove a <code>SizeConstraintSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>SizeConstraintSet</code> to remove filters, if any. For more information, see <a>UpdateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSizeConstraintSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSizeConstraintSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594387 = newJObject()
  if body != nil:
    body_594387 = body
  result = call_594386.call(nil, nil, nil, nil, body_594387)

var deleteSizeConstraintSet* = Call_DeleteSizeConstraintSet_594373(
    name: "deleteSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteSizeConstraintSet",
    validator: validate_DeleteSizeConstraintSet_594374, base: "/",
    url: url_DeleteSizeConstraintSet_594375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSqlInjectionMatchSet_594388 = ref object of OpenApiRestCall_593437
proc url_DeleteSqlInjectionMatchSet_594390(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSqlInjectionMatchSet_594389(path: JsonNode; query: JsonNode;
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
  var valid_594391 = header.getOrDefault("X-Amz-Date")
  valid_594391 = validateParameter(valid_594391, JString, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "X-Amz-Date", valid_594391
  var valid_594392 = header.getOrDefault("X-Amz-Security-Token")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "X-Amz-Security-Token", valid_594392
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594393 = header.getOrDefault("X-Amz-Target")
  valid_594393 = validateParameter(valid_594393, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteSqlInjectionMatchSet"))
  if valid_594393 != nil:
    section.add "X-Amz-Target", valid_594393
  var valid_594394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Content-Sha256", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Algorithm")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Algorithm", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Signature")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Signature", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-SignedHeaders", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Credential")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Credential", valid_594398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594400: Call_DeleteSqlInjectionMatchSet_594388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>SqlInjectionMatchSet</a>. You can't delete a <code>SqlInjectionMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>SqlInjectionMatchTuple</a> objects.</p> <p>If you just want to remove a <code>SqlInjectionMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SqlInjectionMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>SqlInjectionMatchSet</code> to remove filters, if any. For more information, see <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_594400.validator(path, query, header, formData, body)
  let scheme = call_594400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594400.url(scheme.get, call_594400.host, call_594400.base,
                         call_594400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594400, url, valid)

proc call*(call_594401: Call_DeleteSqlInjectionMatchSet_594388; body: JsonNode): Recallable =
  ## deleteSqlInjectionMatchSet
  ## <p>Permanently deletes a <a>SqlInjectionMatchSet</a>. You can't delete a <code>SqlInjectionMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>SqlInjectionMatchTuple</a> objects.</p> <p>If you just want to remove a <code>SqlInjectionMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete a <code>SqlInjectionMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>SqlInjectionMatchSet</code> to remove filters, if any. For more information, see <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteSqlInjectionMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594402 = newJObject()
  if body != nil:
    body_594402 = body
  result = call_594401.call(nil, nil, nil, nil, body_594402)

var deleteSqlInjectionMatchSet* = Call_DeleteSqlInjectionMatchSet_594388(
    name: "deleteSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteSqlInjectionMatchSet",
    validator: validate_DeleteSqlInjectionMatchSet_594389, base: "/",
    url: url_DeleteSqlInjectionMatchSet_594390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteWebACL_594403 = ref object of OpenApiRestCall_593437
proc url_DeleteWebACL_594405(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteWebACL_594404(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594406 = header.getOrDefault("X-Amz-Date")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Date", valid_594406
  var valid_594407 = header.getOrDefault("X-Amz-Security-Token")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = nil)
  if valid_594407 != nil:
    section.add "X-Amz-Security-Token", valid_594407
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594408 = header.getOrDefault("X-Amz-Target")
  valid_594408 = validateParameter(valid_594408, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteWebACL"))
  if valid_594408 != nil:
    section.add "X-Amz-Target", valid_594408
  var valid_594409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "X-Amz-Content-Sha256", valid_594409
  var valid_594410 = header.getOrDefault("X-Amz-Algorithm")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "X-Amz-Algorithm", valid_594410
  var valid_594411 = header.getOrDefault("X-Amz-Signature")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Signature", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-SignedHeaders", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Credential")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Credential", valid_594413
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594415: Call_DeleteWebACL_594403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes a <a>WebACL</a>. You can't delete a <code>WebACL</code> if it still contains any <code>Rules</code>.</p> <p>To delete a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>WebACL</code> to remove <code>Rules</code>, if any. For more information, see <a>UpdateWebACL</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteWebACL</code> request.</p> </li> <li> <p>Submit a <code>DeleteWebACL</code> request.</p> </li> </ol>
  ## 
  let valid = call_594415.validator(path, query, header, formData, body)
  let scheme = call_594415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594415.url(scheme.get, call_594415.host, call_594415.base,
                         call_594415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594415, url, valid)

proc call*(call_594416: Call_DeleteWebACL_594403; body: JsonNode): Recallable =
  ## deleteWebACL
  ## <p>Permanently deletes a <a>WebACL</a>. You can't delete a <code>WebACL</code> if it still contains any <code>Rules</code>.</p> <p>To delete a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Update the <code>WebACL</code> to remove <code>Rules</code>, if any. For more information, see <a>UpdateWebACL</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteWebACL</code> request.</p> </li> <li> <p>Submit a <code>DeleteWebACL</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594417 = newJObject()
  if body != nil:
    body_594417 = body
  result = call_594416.call(nil, nil, nil, nil, body_594417)

var deleteWebACL* = Call_DeleteWebACL_594403(name: "deleteWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteWebACL",
    validator: validate_DeleteWebACL_594404, base: "/", url: url_DeleteWebACL_594405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteXssMatchSet_594418 = ref object of OpenApiRestCall_593437
proc url_DeleteXssMatchSet_594420(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteXssMatchSet_594419(path: JsonNode; query: JsonNode;
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
  var valid_594421 = header.getOrDefault("X-Amz-Date")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Date", valid_594421
  var valid_594422 = header.getOrDefault("X-Amz-Security-Token")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "X-Amz-Security-Token", valid_594422
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594423 = header.getOrDefault("X-Amz-Target")
  valid_594423 = validateParameter(valid_594423, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DeleteXssMatchSet"))
  if valid_594423 != nil:
    section.add "X-Amz-Target", valid_594423
  var valid_594424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Content-Sha256", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Algorithm")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Algorithm", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Signature")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Signature", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-SignedHeaders", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Credential")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Credential", valid_594428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594430: Call_DeleteXssMatchSet_594418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Permanently deletes an <a>XssMatchSet</a>. You can't delete an <code>XssMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>XssMatchTuple</a> objects.</p> <p>If you just want to remove an <code>XssMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>XssMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>XssMatchSet</code> to remove filters, if any. For more information, see <a>UpdateXssMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteXssMatchSet</code> request.</p> </li> </ol>
  ## 
  let valid = call_594430.validator(path, query, header, formData, body)
  let scheme = call_594430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594430.url(scheme.get, call_594430.host, call_594430.base,
                         call_594430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594430, url, valid)

proc call*(call_594431: Call_DeleteXssMatchSet_594418; body: JsonNode): Recallable =
  ## deleteXssMatchSet
  ## <p>Permanently deletes an <a>XssMatchSet</a>. You can't delete an <code>XssMatchSet</code> if it's still used in any <code>Rules</code> or if it still contains any <a>XssMatchTuple</a> objects.</p> <p>If you just want to remove an <code>XssMatchSet</code> from a <code>Rule</code>, use <a>UpdateRule</a>.</p> <p>To permanently delete an <code>XssMatchSet</code> from AWS WAF, perform the following steps:</p> <ol> <li> <p>Update the <code>XssMatchSet</code> to remove filters, if any. For more information, see <a>UpdateXssMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of a <code>DeleteXssMatchSet</code> request.</p> </li> <li> <p>Submit a <code>DeleteXssMatchSet</code> request.</p> </li> </ol>
  ##   body: JObject (required)
  var body_594432 = newJObject()
  if body != nil:
    body_594432 = body
  result = call_594431.call(nil, nil, nil, nil, body_594432)

var deleteXssMatchSet* = Call_DeleteXssMatchSet_594418(name: "deleteXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DeleteXssMatchSet",
    validator: validate_DeleteXssMatchSet_594419, base: "/",
    url: url_DeleteXssMatchSet_594420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateWebACL_594433 = ref object of OpenApiRestCall_593437
proc url_DisassociateWebACL_594435(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DisassociateWebACL_594434(path: JsonNode; query: JsonNode;
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
  var valid_594436 = header.getOrDefault("X-Amz-Date")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Date", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Security-Token")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Security-Token", valid_594437
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594438 = header.getOrDefault("X-Amz-Target")
  valid_594438 = validateParameter(valid_594438, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.DisassociateWebACL"))
  if valid_594438 != nil:
    section.add "X-Amz-Target", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Content-Sha256", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Algorithm")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Algorithm", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Signature")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Signature", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-SignedHeaders", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Credential")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Credential", valid_594443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594445: Call_DisassociateWebACL_594433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a web ACL from the specified resource, either an application load balancer or Amazon API Gateway stage.
  ## 
  let valid = call_594445.validator(path, query, header, formData, body)
  let scheme = call_594445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594445.url(scheme.get, call_594445.host, call_594445.base,
                         call_594445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594445, url, valid)

proc call*(call_594446: Call_DisassociateWebACL_594433; body: JsonNode): Recallable =
  ## disassociateWebACL
  ## Removes a web ACL from the specified resource, either an application load balancer or Amazon API Gateway stage.
  ##   body: JObject (required)
  var body_594447 = newJObject()
  if body != nil:
    body_594447 = body
  result = call_594446.call(nil, nil, nil, nil, body_594447)

var disassociateWebACL* = Call_DisassociateWebACL_594433(
    name: "disassociateWebACL", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.DisassociateWebACL",
    validator: validate_DisassociateWebACL_594434, base: "/",
    url: url_DisassociateWebACL_594435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetByteMatchSet_594448 = ref object of OpenApiRestCall_593437
proc url_GetByteMatchSet_594450(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetByteMatchSet_594449(path: JsonNode; query: JsonNode;
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
  var valid_594451 = header.getOrDefault("X-Amz-Date")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Date", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Security-Token")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Security-Token", valid_594452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594453 = header.getOrDefault("X-Amz-Target")
  valid_594453 = validateParameter(valid_594453, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetByteMatchSet"))
  if valid_594453 != nil:
    section.add "X-Amz-Target", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Content-Sha256", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Algorithm")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Algorithm", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Signature")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Signature", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-SignedHeaders", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Credential")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Credential", valid_594458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594460: Call_GetByteMatchSet_594448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>ByteMatchSet</a> specified by <code>ByteMatchSetId</code>.
  ## 
  let valid = call_594460.validator(path, query, header, formData, body)
  let scheme = call_594460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594460.url(scheme.get, call_594460.host, call_594460.base,
                         call_594460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594460, url, valid)

proc call*(call_594461: Call_GetByteMatchSet_594448; body: JsonNode): Recallable =
  ## getByteMatchSet
  ## Returns the <a>ByteMatchSet</a> specified by <code>ByteMatchSetId</code>.
  ##   body: JObject (required)
  var body_594462 = newJObject()
  if body != nil:
    body_594462 = body
  result = call_594461.call(nil, nil, nil, nil, body_594462)

var getByteMatchSet* = Call_GetByteMatchSet_594448(name: "getByteMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetByteMatchSet",
    validator: validate_GetByteMatchSet_594449, base: "/", url: url_GetByteMatchSet_594450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeToken_594463 = ref object of OpenApiRestCall_593437
proc url_GetChangeToken_594465(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetChangeToken_594464(path: JsonNode; query: JsonNode;
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
  var valid_594466 = header.getOrDefault("X-Amz-Date")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Date", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Security-Token")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Security-Token", valid_594467
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594468 = header.getOrDefault("X-Amz-Target")
  valid_594468 = validateParameter(valid_594468, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetChangeToken"))
  if valid_594468 != nil:
    section.add "X-Amz-Target", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Content-Sha256", valid_594469
  var valid_594470 = header.getOrDefault("X-Amz-Algorithm")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Algorithm", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Signature")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Signature", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-SignedHeaders", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Credential")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Credential", valid_594473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594475: Call_GetChangeToken_594463; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>When you want to create, update, or delete AWS WAF objects, get a change token and include the change token in the create, update, or delete request. Change tokens ensure that your application doesn't submit conflicting requests to AWS WAF.</p> <p>Each create, update, or delete request must use a unique change token. If your application submits a <code>GetChangeToken</code> request and then submits a second <code>GetChangeToken</code> request before submitting a create, update, or delete request, the second <code>GetChangeToken</code> request returns the same value as the first <code>GetChangeToken</code> request.</p> <p>When you use a change token in a create, update, or delete request, the status of the change token changes to <code>PENDING</code>, which indicates that AWS WAF is propagating the change to all AWS WAF servers. Use <code>GetChangeTokenStatus</code> to determine the status of your change token.</p>
  ## 
  let valid = call_594475.validator(path, query, header, formData, body)
  let scheme = call_594475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594475.url(scheme.get, call_594475.host, call_594475.base,
                         call_594475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594475, url, valid)

proc call*(call_594476: Call_GetChangeToken_594463; body: JsonNode): Recallable =
  ## getChangeToken
  ## <p>When you want to create, update, or delete AWS WAF objects, get a change token and include the change token in the create, update, or delete request. Change tokens ensure that your application doesn't submit conflicting requests to AWS WAF.</p> <p>Each create, update, or delete request must use a unique change token. If your application submits a <code>GetChangeToken</code> request and then submits a second <code>GetChangeToken</code> request before submitting a create, update, or delete request, the second <code>GetChangeToken</code> request returns the same value as the first <code>GetChangeToken</code> request.</p> <p>When you use a change token in a create, update, or delete request, the status of the change token changes to <code>PENDING</code>, which indicates that AWS WAF is propagating the change to all AWS WAF servers. Use <code>GetChangeTokenStatus</code> to determine the status of your change token.</p>
  ##   body: JObject (required)
  var body_594477 = newJObject()
  if body != nil:
    body_594477 = body
  result = call_594476.call(nil, nil, nil, nil, body_594477)

var getChangeToken* = Call_GetChangeToken_594463(name: "getChangeToken",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetChangeToken",
    validator: validate_GetChangeToken_594464, base: "/", url: url_GetChangeToken_594465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetChangeTokenStatus_594478 = ref object of OpenApiRestCall_593437
proc url_GetChangeTokenStatus_594480(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetChangeTokenStatus_594479(path: JsonNode; query: JsonNode;
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
  var valid_594481 = header.getOrDefault("X-Amz-Date")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Date", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Security-Token")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Security-Token", valid_594482
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594483 = header.getOrDefault("X-Amz-Target")
  valid_594483 = validateParameter(valid_594483, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetChangeTokenStatus"))
  if valid_594483 != nil:
    section.add "X-Amz-Target", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-Content-Sha256", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Algorithm")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Algorithm", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Signature")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Signature", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-SignedHeaders", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Credential")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Credential", valid_594488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594490: Call_GetChangeTokenStatus_594478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the status of a <code>ChangeToken</code> that you got by calling <a>GetChangeToken</a>. <code>ChangeTokenStatus</code> is one of the following values:</p> <ul> <li> <p> <code>PROVISIONED</code>: You requested the change token by calling <code>GetChangeToken</code>, but you haven't used it yet in a call to create, update, or delete an AWS WAF object.</p> </li> <li> <p> <code>PENDING</code>: AWS WAF is propagating the create, update, or delete request to all AWS WAF servers.</p> </li> <li> <p> <code>INSYNC</code>: Propagation is complete.</p> </li> </ul>
  ## 
  let valid = call_594490.validator(path, query, header, formData, body)
  let scheme = call_594490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594490.url(scheme.get, call_594490.host, call_594490.base,
                         call_594490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594490, url, valid)

proc call*(call_594491: Call_GetChangeTokenStatus_594478; body: JsonNode): Recallable =
  ## getChangeTokenStatus
  ## <p>Returns the status of a <code>ChangeToken</code> that you got by calling <a>GetChangeToken</a>. <code>ChangeTokenStatus</code> is one of the following values:</p> <ul> <li> <p> <code>PROVISIONED</code>: You requested the change token by calling <code>GetChangeToken</code>, but you haven't used it yet in a call to create, update, or delete an AWS WAF object.</p> </li> <li> <p> <code>PENDING</code>: AWS WAF is propagating the create, update, or delete request to all AWS WAF servers.</p> </li> <li> <p> <code>INSYNC</code>: Propagation is complete.</p> </li> </ul>
  ##   body: JObject (required)
  var body_594492 = newJObject()
  if body != nil:
    body_594492 = body
  result = call_594491.call(nil, nil, nil, nil, body_594492)

var getChangeTokenStatus* = Call_GetChangeTokenStatus_594478(
    name: "getChangeTokenStatus", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetChangeTokenStatus",
    validator: validate_GetChangeTokenStatus_594479, base: "/",
    url: url_GetChangeTokenStatus_594480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGeoMatchSet_594493 = ref object of OpenApiRestCall_593437
proc url_GetGeoMatchSet_594495(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetGeoMatchSet_594494(path: JsonNode; query: JsonNode;
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
  var valid_594496 = header.getOrDefault("X-Amz-Date")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Date", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Security-Token")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Security-Token", valid_594497
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594498 = header.getOrDefault("X-Amz-Target")
  valid_594498 = validateParameter(valid_594498, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetGeoMatchSet"))
  if valid_594498 != nil:
    section.add "X-Amz-Target", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Content-Sha256", valid_594499
  var valid_594500 = header.getOrDefault("X-Amz-Algorithm")
  valid_594500 = validateParameter(valid_594500, JString, required = false,
                                 default = nil)
  if valid_594500 != nil:
    section.add "X-Amz-Algorithm", valid_594500
  var valid_594501 = header.getOrDefault("X-Amz-Signature")
  valid_594501 = validateParameter(valid_594501, JString, required = false,
                                 default = nil)
  if valid_594501 != nil:
    section.add "X-Amz-Signature", valid_594501
  var valid_594502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-SignedHeaders", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Credential")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Credential", valid_594503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594505: Call_GetGeoMatchSet_594493; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>GeoMatchSet</a> that is specified by <code>GeoMatchSetId</code>.
  ## 
  let valid = call_594505.validator(path, query, header, formData, body)
  let scheme = call_594505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594505.url(scheme.get, call_594505.host, call_594505.base,
                         call_594505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594505, url, valid)

proc call*(call_594506: Call_GetGeoMatchSet_594493; body: JsonNode): Recallable =
  ## getGeoMatchSet
  ## Returns the <a>GeoMatchSet</a> that is specified by <code>GeoMatchSetId</code>.
  ##   body: JObject (required)
  var body_594507 = newJObject()
  if body != nil:
    body_594507 = body
  result = call_594506.call(nil, nil, nil, nil, body_594507)

var getGeoMatchSet* = Call_GetGeoMatchSet_594493(name: "getGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetGeoMatchSet",
    validator: validate_GetGeoMatchSet_594494, base: "/", url: url_GetGeoMatchSet_594495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIPSet_594508 = ref object of OpenApiRestCall_593437
proc url_GetIPSet_594510(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIPSet_594509(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594511 = header.getOrDefault("X-Amz-Date")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Date", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Security-Token")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Security-Token", valid_594512
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594513 = header.getOrDefault("X-Amz-Target")
  valid_594513 = validateParameter(valid_594513, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetIPSet"))
  if valid_594513 != nil:
    section.add "X-Amz-Target", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Content-Sha256", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Algorithm")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Algorithm", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Signature")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Signature", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-SignedHeaders", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-Credential")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Credential", valid_594518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594520: Call_GetIPSet_594508; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>IPSet</a> that is specified by <code>IPSetId</code>.
  ## 
  let valid = call_594520.validator(path, query, header, formData, body)
  let scheme = call_594520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594520.url(scheme.get, call_594520.host, call_594520.base,
                         call_594520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594520, url, valid)

proc call*(call_594521: Call_GetIPSet_594508; body: JsonNode): Recallable =
  ## getIPSet
  ## Returns the <a>IPSet</a> that is specified by <code>IPSetId</code>.
  ##   body: JObject (required)
  var body_594522 = newJObject()
  if body != nil:
    body_594522 = body
  result = call_594521.call(nil, nil, nil, nil, body_594522)

var getIPSet* = Call_GetIPSet_594508(name: "getIPSet", meth: HttpMethod.HttpPost,
                                  host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetIPSet",
                                  validator: validate_GetIPSet_594509, base: "/",
                                  url: url_GetIPSet_594510,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLoggingConfiguration_594523 = ref object of OpenApiRestCall_593437
proc url_GetLoggingConfiguration_594525(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetLoggingConfiguration_594524(path: JsonNode; query: JsonNode;
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
  var valid_594526 = header.getOrDefault("X-Amz-Date")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Date", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Security-Token")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Security-Token", valid_594527
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594528 = header.getOrDefault("X-Amz-Target")
  valid_594528 = validateParameter(valid_594528, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetLoggingConfiguration"))
  if valid_594528 != nil:
    section.add "X-Amz-Target", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Content-Sha256", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Algorithm")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Algorithm", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Signature")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Signature", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-SignedHeaders", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-Credential")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-Credential", valid_594533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594535: Call_GetLoggingConfiguration_594523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>LoggingConfiguration</a> for the specified web ACL.
  ## 
  let valid = call_594535.validator(path, query, header, formData, body)
  let scheme = call_594535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594535.url(scheme.get, call_594535.host, call_594535.base,
                         call_594535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594535, url, valid)

proc call*(call_594536: Call_GetLoggingConfiguration_594523; body: JsonNode): Recallable =
  ## getLoggingConfiguration
  ## Returns the <a>LoggingConfiguration</a> for the specified web ACL.
  ##   body: JObject (required)
  var body_594537 = newJObject()
  if body != nil:
    body_594537 = body
  result = call_594536.call(nil, nil, nil, nil, body_594537)

var getLoggingConfiguration* = Call_GetLoggingConfiguration_594523(
    name: "getLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetLoggingConfiguration",
    validator: validate_GetLoggingConfiguration_594524, base: "/",
    url: url_GetLoggingConfiguration_594525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPermissionPolicy_594538 = ref object of OpenApiRestCall_593437
proc url_GetPermissionPolicy_594540(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPermissionPolicy_594539(path: JsonNode; query: JsonNode;
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
  var valid_594541 = header.getOrDefault("X-Amz-Date")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Date", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Security-Token")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Security-Token", valid_594542
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594543 = header.getOrDefault("X-Amz-Target")
  valid_594543 = validateParameter(valid_594543, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetPermissionPolicy"))
  if valid_594543 != nil:
    section.add "X-Amz-Target", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Content-Sha256", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-Algorithm")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Algorithm", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Signature")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Signature", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-SignedHeaders", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Credential")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Credential", valid_594548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594550: Call_GetPermissionPolicy_594538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the IAM policy attached to the RuleGroup.
  ## 
  let valid = call_594550.validator(path, query, header, formData, body)
  let scheme = call_594550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594550.url(scheme.get, call_594550.host, call_594550.base,
                         call_594550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594550, url, valid)

proc call*(call_594551: Call_GetPermissionPolicy_594538; body: JsonNode): Recallable =
  ## getPermissionPolicy
  ## Returns the IAM policy attached to the RuleGroup.
  ##   body: JObject (required)
  var body_594552 = newJObject()
  if body != nil:
    body_594552 = body
  result = call_594551.call(nil, nil, nil, nil, body_594552)

var getPermissionPolicy* = Call_GetPermissionPolicy_594538(
    name: "getPermissionPolicy", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetPermissionPolicy",
    validator: validate_GetPermissionPolicy_594539, base: "/",
    url: url_GetPermissionPolicy_594540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRateBasedRule_594553 = ref object of OpenApiRestCall_593437
proc url_GetRateBasedRule_594555(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRateBasedRule_594554(path: JsonNode; query: JsonNode;
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
  var valid_594556 = header.getOrDefault("X-Amz-Date")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Date", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Security-Token")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Security-Token", valid_594557
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594558 = header.getOrDefault("X-Amz-Target")
  valid_594558 = validateParameter(valid_594558, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRateBasedRule"))
  if valid_594558 != nil:
    section.add "X-Amz-Target", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Content-Sha256", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Algorithm")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Algorithm", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Signature")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Signature", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-SignedHeaders", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Credential")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Credential", valid_594563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594565: Call_GetRateBasedRule_594553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>RateBasedRule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRateBasedRule</code> request.
  ## 
  let valid = call_594565.validator(path, query, header, formData, body)
  let scheme = call_594565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594565.url(scheme.get, call_594565.host, call_594565.base,
                         call_594565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594565, url, valid)

proc call*(call_594566: Call_GetRateBasedRule_594553; body: JsonNode): Recallable =
  ## getRateBasedRule
  ## Returns the <a>RateBasedRule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRateBasedRule</code> request.
  ##   body: JObject (required)
  var body_594567 = newJObject()
  if body != nil:
    body_594567 = body
  result = call_594566.call(nil, nil, nil, nil, body_594567)

var getRateBasedRule* = Call_GetRateBasedRule_594553(name: "getRateBasedRule",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRateBasedRule",
    validator: validate_GetRateBasedRule_594554, base: "/",
    url: url_GetRateBasedRule_594555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRateBasedRuleManagedKeys_594568 = ref object of OpenApiRestCall_593437
proc url_GetRateBasedRuleManagedKeys_594570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRateBasedRuleManagedKeys_594569(path: JsonNode; query: JsonNode;
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
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Security-Token")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Security-Token", valid_594572
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594573 = header.getOrDefault("X-Amz-Target")
  valid_594573 = validateParameter(valid_594573, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRateBasedRuleManagedKeys"))
  if valid_594573 != nil:
    section.add "X-Amz-Target", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Content-Sha256", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Algorithm")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Algorithm", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-Signature")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-Signature", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-SignedHeaders", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Credential")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Credential", valid_594578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594580: Call_GetRateBasedRuleManagedKeys_594568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of IP addresses currently being blocked by the <a>RateBasedRule</a> that is specified by the <code>RuleId</code>. The maximum number of managed keys that will be blocked is 10,000. If more than 10,000 addresses exceed the rate limit, the 10,000 addresses with the highest rates will be blocked.
  ## 
  let valid = call_594580.validator(path, query, header, formData, body)
  let scheme = call_594580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594580.url(scheme.get, call_594580.host, call_594580.base,
                         call_594580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594580, url, valid)

proc call*(call_594581: Call_GetRateBasedRuleManagedKeys_594568; body: JsonNode): Recallable =
  ## getRateBasedRuleManagedKeys
  ## Returns an array of IP addresses currently being blocked by the <a>RateBasedRule</a> that is specified by the <code>RuleId</code>. The maximum number of managed keys that will be blocked is 10,000. If more than 10,000 addresses exceed the rate limit, the 10,000 addresses with the highest rates will be blocked.
  ##   body: JObject (required)
  var body_594582 = newJObject()
  if body != nil:
    body_594582 = body
  result = call_594581.call(nil, nil, nil, nil, body_594582)

var getRateBasedRuleManagedKeys* = Call_GetRateBasedRuleManagedKeys_594568(
    name: "getRateBasedRuleManagedKeys", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRateBasedRuleManagedKeys",
    validator: validate_GetRateBasedRuleManagedKeys_594569, base: "/",
    url: url_GetRateBasedRuleManagedKeys_594570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegexMatchSet_594583 = ref object of OpenApiRestCall_593437
proc url_GetRegexMatchSet_594585(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegexMatchSet_594584(path: JsonNode; query: JsonNode;
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
  var valid_594586 = header.getOrDefault("X-Amz-Date")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Date", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-Security-Token")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Security-Token", valid_594587
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594588 = header.getOrDefault("X-Amz-Target")
  valid_594588 = validateParameter(valid_594588, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRegexMatchSet"))
  if valid_594588 != nil:
    section.add "X-Amz-Target", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Content-Sha256", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Algorithm")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Algorithm", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Signature")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Signature", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-SignedHeaders", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Credential")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Credential", valid_594593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594595: Call_GetRegexMatchSet_594583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>RegexMatchSet</a> specified by <code>RegexMatchSetId</code>.
  ## 
  let valid = call_594595.validator(path, query, header, formData, body)
  let scheme = call_594595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594595.url(scheme.get, call_594595.host, call_594595.base,
                         call_594595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594595, url, valid)

proc call*(call_594596: Call_GetRegexMatchSet_594583; body: JsonNode): Recallable =
  ## getRegexMatchSet
  ## Returns the <a>RegexMatchSet</a> specified by <code>RegexMatchSetId</code>.
  ##   body: JObject (required)
  var body_594597 = newJObject()
  if body != nil:
    body_594597 = body
  result = call_594596.call(nil, nil, nil, nil, body_594597)

var getRegexMatchSet* = Call_GetRegexMatchSet_594583(name: "getRegexMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRegexMatchSet",
    validator: validate_GetRegexMatchSet_594584, base: "/",
    url: url_GetRegexMatchSet_594585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRegexPatternSet_594598 = ref object of OpenApiRestCall_593437
proc url_GetRegexPatternSet_594600(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRegexPatternSet_594599(path: JsonNode; query: JsonNode;
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
  var valid_594601 = header.getOrDefault("X-Amz-Date")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Date", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-Security-Token")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Security-Token", valid_594602
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594603 = header.getOrDefault("X-Amz-Target")
  valid_594603 = validateParameter(valid_594603, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRegexPatternSet"))
  if valid_594603 != nil:
    section.add "X-Amz-Target", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Content-Sha256", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Algorithm")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Algorithm", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-SignedHeaders", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Credential")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Credential", valid_594608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594610: Call_GetRegexPatternSet_594598; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>RegexPatternSet</a> specified by <code>RegexPatternSetId</code>.
  ## 
  let valid = call_594610.validator(path, query, header, formData, body)
  let scheme = call_594610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594610.url(scheme.get, call_594610.host, call_594610.base,
                         call_594610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594610, url, valid)

proc call*(call_594611: Call_GetRegexPatternSet_594598; body: JsonNode): Recallable =
  ## getRegexPatternSet
  ## Returns the <a>RegexPatternSet</a> specified by <code>RegexPatternSetId</code>.
  ##   body: JObject (required)
  var body_594612 = newJObject()
  if body != nil:
    body_594612 = body
  result = call_594611.call(nil, nil, nil, nil, body_594612)

var getRegexPatternSet* = Call_GetRegexPatternSet_594598(
    name: "getRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRegexPatternSet",
    validator: validate_GetRegexPatternSet_594599, base: "/",
    url: url_GetRegexPatternSet_594600, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRule_594613 = ref object of OpenApiRestCall_593437
proc url_GetRule_594615(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRule_594614(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594616 = header.getOrDefault("X-Amz-Date")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-Date", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Security-Token")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Security-Token", valid_594617
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594618 = header.getOrDefault("X-Amz-Target")
  valid_594618 = validateParameter(valid_594618, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRule"))
  if valid_594618 != nil:
    section.add "X-Amz-Target", valid_594618
  var valid_594619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594619 = validateParameter(valid_594619, JString, required = false,
                                 default = nil)
  if valid_594619 != nil:
    section.add "X-Amz-Content-Sha256", valid_594619
  var valid_594620 = header.getOrDefault("X-Amz-Algorithm")
  valid_594620 = validateParameter(valid_594620, JString, required = false,
                                 default = nil)
  if valid_594620 != nil:
    section.add "X-Amz-Algorithm", valid_594620
  var valid_594621 = header.getOrDefault("X-Amz-Signature")
  valid_594621 = validateParameter(valid_594621, JString, required = false,
                                 default = nil)
  if valid_594621 != nil:
    section.add "X-Amz-Signature", valid_594621
  var valid_594622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594622 = validateParameter(valid_594622, JString, required = false,
                                 default = nil)
  if valid_594622 != nil:
    section.add "X-Amz-SignedHeaders", valid_594622
  var valid_594623 = header.getOrDefault("X-Amz-Credential")
  valid_594623 = validateParameter(valid_594623, JString, required = false,
                                 default = nil)
  if valid_594623 != nil:
    section.add "X-Amz-Credential", valid_594623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594625: Call_GetRule_594613; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>Rule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRule</code> request.
  ## 
  let valid = call_594625.validator(path, query, header, formData, body)
  let scheme = call_594625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594625.url(scheme.get, call_594625.host, call_594625.base,
                         call_594625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594625, url, valid)

proc call*(call_594626: Call_GetRule_594613; body: JsonNode): Recallable =
  ## getRule
  ## Returns the <a>Rule</a> that is specified by the <code>RuleId</code> that you included in the <code>GetRule</code> request.
  ##   body: JObject (required)
  var body_594627 = newJObject()
  if body != nil:
    body_594627 = body
  result = call_594626.call(nil, nil, nil, nil, body_594627)

var getRule* = Call_GetRule_594613(name: "getRule", meth: HttpMethod.HttpPost,
                                host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRule",
                                validator: validate_GetRule_594614, base: "/",
                                url: url_GetRule_594615,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRuleGroup_594628 = ref object of OpenApiRestCall_593437
proc url_GetRuleGroup_594630(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRuleGroup_594629(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594631 = header.getOrDefault("X-Amz-Date")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Date", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Security-Token")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Security-Token", valid_594632
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594633 = header.getOrDefault("X-Amz-Target")
  valid_594633 = validateParameter(valid_594633, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetRuleGroup"))
  if valid_594633 != nil:
    section.add "X-Amz-Target", valid_594633
  var valid_594634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594634 = validateParameter(valid_594634, JString, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "X-Amz-Content-Sha256", valid_594634
  var valid_594635 = header.getOrDefault("X-Amz-Algorithm")
  valid_594635 = validateParameter(valid_594635, JString, required = false,
                                 default = nil)
  if valid_594635 != nil:
    section.add "X-Amz-Algorithm", valid_594635
  var valid_594636 = header.getOrDefault("X-Amz-Signature")
  valid_594636 = validateParameter(valid_594636, JString, required = false,
                                 default = nil)
  if valid_594636 != nil:
    section.add "X-Amz-Signature", valid_594636
  var valid_594637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594637 = validateParameter(valid_594637, JString, required = false,
                                 default = nil)
  if valid_594637 != nil:
    section.add "X-Amz-SignedHeaders", valid_594637
  var valid_594638 = header.getOrDefault("X-Amz-Credential")
  valid_594638 = validateParameter(valid_594638, JString, required = false,
                                 default = nil)
  if valid_594638 != nil:
    section.add "X-Amz-Credential", valid_594638
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594640: Call_GetRuleGroup_594628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the <a>RuleGroup</a> that is specified by the <code>RuleGroupId</code> that you included in the <code>GetRuleGroup</code> request.</p> <p>To view the rules in a rule group, use <a>ListActivatedRulesInRuleGroup</a>.</p>
  ## 
  let valid = call_594640.validator(path, query, header, formData, body)
  let scheme = call_594640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594640.url(scheme.get, call_594640.host, call_594640.base,
                         call_594640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594640, url, valid)

proc call*(call_594641: Call_GetRuleGroup_594628; body: JsonNode): Recallable =
  ## getRuleGroup
  ## <p>Returns the <a>RuleGroup</a> that is specified by the <code>RuleGroupId</code> that you included in the <code>GetRuleGroup</code> request.</p> <p>To view the rules in a rule group, use <a>ListActivatedRulesInRuleGroup</a>.</p>
  ##   body: JObject (required)
  var body_594642 = newJObject()
  if body != nil:
    body_594642 = body
  result = call_594641.call(nil, nil, nil, nil, body_594642)

var getRuleGroup* = Call_GetRuleGroup_594628(name: "getRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetRuleGroup",
    validator: validate_GetRuleGroup_594629, base: "/", url: url_GetRuleGroup_594630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSampledRequests_594643 = ref object of OpenApiRestCall_593437
proc url_GetSampledRequests_594645(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSampledRequests_594644(path: JsonNode; query: JsonNode;
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
  var valid_594646 = header.getOrDefault("X-Amz-Date")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Date", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Security-Token")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Security-Token", valid_594647
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594648 = header.getOrDefault("X-Amz-Target")
  valid_594648 = validateParameter(valid_594648, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetSampledRequests"))
  if valid_594648 != nil:
    section.add "X-Amz-Target", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Content-Sha256", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Algorithm")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Algorithm", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Signature")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Signature", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-SignedHeaders", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Credential")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Credential", valid_594653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594655: Call_GetSampledRequests_594643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
  ## 
  let valid = call_594655.validator(path, query, header, formData, body)
  let scheme = call_594655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594655.url(scheme.get, call_594655.host, call_594655.base,
                         call_594655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594655, url, valid)

proc call*(call_594656: Call_GetSampledRequests_594643; body: JsonNode): Recallable =
  ## getSampledRequests
  ## <p>Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours.</p> <p> <code>GetSampledRequests</code> returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, <code>GetSampledRequests</code> returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.</p>
  ##   body: JObject (required)
  var body_594657 = newJObject()
  if body != nil:
    body_594657 = body
  result = call_594656.call(nil, nil, nil, nil, body_594657)

var getSampledRequests* = Call_GetSampledRequests_594643(
    name: "getSampledRequests", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetSampledRequests",
    validator: validate_GetSampledRequests_594644, base: "/",
    url: url_GetSampledRequests_594645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSizeConstraintSet_594658 = ref object of OpenApiRestCall_593437
proc url_GetSizeConstraintSet_594660(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSizeConstraintSet_594659(path: JsonNode; query: JsonNode;
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
  var valid_594661 = header.getOrDefault("X-Amz-Date")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Date", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Security-Token")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Security-Token", valid_594662
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594663 = header.getOrDefault("X-Amz-Target")
  valid_594663 = validateParameter(valid_594663, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetSizeConstraintSet"))
  if valid_594663 != nil:
    section.add "X-Amz-Target", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Content-Sha256", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Algorithm")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Algorithm", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Signature")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Signature", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-SignedHeaders", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Credential")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Credential", valid_594668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594670: Call_GetSizeConstraintSet_594658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>SizeConstraintSet</a> specified by <code>SizeConstraintSetId</code>.
  ## 
  let valid = call_594670.validator(path, query, header, formData, body)
  let scheme = call_594670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594670.url(scheme.get, call_594670.host, call_594670.base,
                         call_594670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594670, url, valid)

proc call*(call_594671: Call_GetSizeConstraintSet_594658; body: JsonNode): Recallable =
  ## getSizeConstraintSet
  ## Returns the <a>SizeConstraintSet</a> specified by <code>SizeConstraintSetId</code>.
  ##   body: JObject (required)
  var body_594672 = newJObject()
  if body != nil:
    body_594672 = body
  result = call_594671.call(nil, nil, nil, nil, body_594672)

var getSizeConstraintSet* = Call_GetSizeConstraintSet_594658(
    name: "getSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetSizeConstraintSet",
    validator: validate_GetSizeConstraintSet_594659, base: "/",
    url: url_GetSizeConstraintSet_594660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSqlInjectionMatchSet_594673 = ref object of OpenApiRestCall_593437
proc url_GetSqlInjectionMatchSet_594675(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSqlInjectionMatchSet_594674(path: JsonNode; query: JsonNode;
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
  var valid_594676 = header.getOrDefault("X-Amz-Date")
  valid_594676 = validateParameter(valid_594676, JString, required = false,
                                 default = nil)
  if valid_594676 != nil:
    section.add "X-Amz-Date", valid_594676
  var valid_594677 = header.getOrDefault("X-Amz-Security-Token")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Security-Token", valid_594677
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594678 = header.getOrDefault("X-Amz-Target")
  valid_594678 = validateParameter(valid_594678, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetSqlInjectionMatchSet"))
  if valid_594678 != nil:
    section.add "X-Amz-Target", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Content-Sha256", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Algorithm")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Algorithm", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Signature")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Signature", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-SignedHeaders", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Credential")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Credential", valid_594683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594685: Call_GetSqlInjectionMatchSet_594673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>SqlInjectionMatchSet</a> that is specified by <code>SqlInjectionMatchSetId</code>.
  ## 
  let valid = call_594685.validator(path, query, header, formData, body)
  let scheme = call_594685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594685.url(scheme.get, call_594685.host, call_594685.base,
                         call_594685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594685, url, valid)

proc call*(call_594686: Call_GetSqlInjectionMatchSet_594673; body: JsonNode): Recallable =
  ## getSqlInjectionMatchSet
  ## Returns the <a>SqlInjectionMatchSet</a> that is specified by <code>SqlInjectionMatchSetId</code>.
  ##   body: JObject (required)
  var body_594687 = newJObject()
  if body != nil:
    body_594687 = body
  result = call_594686.call(nil, nil, nil, nil, body_594687)

var getSqlInjectionMatchSet* = Call_GetSqlInjectionMatchSet_594673(
    name: "getSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetSqlInjectionMatchSet",
    validator: validate_GetSqlInjectionMatchSet_594674, base: "/",
    url: url_GetSqlInjectionMatchSet_594675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebACL_594688 = ref object of OpenApiRestCall_593437
proc url_GetWebACL_594690(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWebACL_594689(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594691 = header.getOrDefault("X-Amz-Date")
  valid_594691 = validateParameter(valid_594691, JString, required = false,
                                 default = nil)
  if valid_594691 != nil:
    section.add "X-Amz-Date", valid_594691
  var valid_594692 = header.getOrDefault("X-Amz-Security-Token")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Security-Token", valid_594692
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594693 = header.getOrDefault("X-Amz-Target")
  valid_594693 = validateParameter(valid_594693, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetWebACL"))
  if valid_594693 != nil:
    section.add "X-Amz-Target", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Content-Sha256", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Algorithm")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Algorithm", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Signature")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Signature", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-SignedHeaders", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Credential")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Credential", valid_594698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594700: Call_GetWebACL_594688; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>WebACL</a> that is specified by <code>WebACLId</code>.
  ## 
  let valid = call_594700.validator(path, query, header, formData, body)
  let scheme = call_594700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594700.url(scheme.get, call_594700.host, call_594700.base,
                         call_594700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594700, url, valid)

proc call*(call_594701: Call_GetWebACL_594688; body: JsonNode): Recallable =
  ## getWebACL
  ## Returns the <a>WebACL</a> that is specified by <code>WebACLId</code>.
  ##   body: JObject (required)
  var body_594702 = newJObject()
  if body != nil:
    body_594702 = body
  result = call_594701.call(nil, nil, nil, nil, body_594702)

var getWebACL* = Call_GetWebACL_594688(name: "getWebACL", meth: HttpMethod.HttpPost,
                                    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetWebACL",
                                    validator: validate_GetWebACL_594689,
                                    base: "/", url: url_GetWebACL_594690,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetWebACLForResource_594703 = ref object of OpenApiRestCall_593437
proc url_GetWebACLForResource_594705(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetWebACLForResource_594704(path: JsonNode; query: JsonNode;
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
  var valid_594706 = header.getOrDefault("X-Amz-Date")
  valid_594706 = validateParameter(valid_594706, JString, required = false,
                                 default = nil)
  if valid_594706 != nil:
    section.add "X-Amz-Date", valid_594706
  var valid_594707 = header.getOrDefault("X-Amz-Security-Token")
  valid_594707 = validateParameter(valid_594707, JString, required = false,
                                 default = nil)
  if valid_594707 != nil:
    section.add "X-Amz-Security-Token", valid_594707
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594708 = header.getOrDefault("X-Amz-Target")
  valid_594708 = validateParameter(valid_594708, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetWebACLForResource"))
  if valid_594708 != nil:
    section.add "X-Amz-Target", valid_594708
  var valid_594709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594709 = validateParameter(valid_594709, JString, required = false,
                                 default = nil)
  if valid_594709 != nil:
    section.add "X-Amz-Content-Sha256", valid_594709
  var valid_594710 = header.getOrDefault("X-Amz-Algorithm")
  valid_594710 = validateParameter(valid_594710, JString, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "X-Amz-Algorithm", valid_594710
  var valid_594711 = header.getOrDefault("X-Amz-Signature")
  valid_594711 = validateParameter(valid_594711, JString, required = false,
                                 default = nil)
  if valid_594711 != nil:
    section.add "X-Amz-Signature", valid_594711
  var valid_594712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594712 = validateParameter(valid_594712, JString, required = false,
                                 default = nil)
  if valid_594712 != nil:
    section.add "X-Amz-SignedHeaders", valid_594712
  var valid_594713 = header.getOrDefault("X-Amz-Credential")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Credential", valid_594713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594715: Call_GetWebACLForResource_594703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the web ACL for the specified resource, either an application load balancer or Amazon API Gateway stage.
  ## 
  let valid = call_594715.validator(path, query, header, formData, body)
  let scheme = call_594715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594715.url(scheme.get, call_594715.host, call_594715.base,
                         call_594715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594715, url, valid)

proc call*(call_594716: Call_GetWebACLForResource_594703; body: JsonNode): Recallable =
  ## getWebACLForResource
  ## Returns the web ACL for the specified resource, either an application load balancer or Amazon API Gateway stage.
  ##   body: JObject (required)
  var body_594717 = newJObject()
  if body != nil:
    body_594717 = body
  result = call_594716.call(nil, nil, nil, nil, body_594717)

var getWebACLForResource* = Call_GetWebACLForResource_594703(
    name: "getWebACLForResource", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetWebACLForResource",
    validator: validate_GetWebACLForResource_594704, base: "/",
    url: url_GetWebACLForResource_594705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetXssMatchSet_594718 = ref object of OpenApiRestCall_593437
proc url_GetXssMatchSet_594720(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetXssMatchSet_594719(path: JsonNode; query: JsonNode;
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
  var valid_594721 = header.getOrDefault("X-Amz-Date")
  valid_594721 = validateParameter(valid_594721, JString, required = false,
                                 default = nil)
  if valid_594721 != nil:
    section.add "X-Amz-Date", valid_594721
  var valid_594722 = header.getOrDefault("X-Amz-Security-Token")
  valid_594722 = validateParameter(valid_594722, JString, required = false,
                                 default = nil)
  if valid_594722 != nil:
    section.add "X-Amz-Security-Token", valid_594722
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594723 = header.getOrDefault("X-Amz-Target")
  valid_594723 = validateParameter(valid_594723, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.GetXssMatchSet"))
  if valid_594723 != nil:
    section.add "X-Amz-Target", valid_594723
  var valid_594724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594724 = validateParameter(valid_594724, JString, required = false,
                                 default = nil)
  if valid_594724 != nil:
    section.add "X-Amz-Content-Sha256", valid_594724
  var valid_594725 = header.getOrDefault("X-Amz-Algorithm")
  valid_594725 = validateParameter(valid_594725, JString, required = false,
                                 default = nil)
  if valid_594725 != nil:
    section.add "X-Amz-Algorithm", valid_594725
  var valid_594726 = header.getOrDefault("X-Amz-Signature")
  valid_594726 = validateParameter(valid_594726, JString, required = false,
                                 default = nil)
  if valid_594726 != nil:
    section.add "X-Amz-Signature", valid_594726
  var valid_594727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594727 = validateParameter(valid_594727, JString, required = false,
                                 default = nil)
  if valid_594727 != nil:
    section.add "X-Amz-SignedHeaders", valid_594727
  var valid_594728 = header.getOrDefault("X-Amz-Credential")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Credential", valid_594728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594730: Call_GetXssMatchSet_594718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a>XssMatchSet</a> that is specified by <code>XssMatchSetId</code>.
  ## 
  let valid = call_594730.validator(path, query, header, formData, body)
  let scheme = call_594730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594730.url(scheme.get, call_594730.host, call_594730.base,
                         call_594730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594730, url, valid)

proc call*(call_594731: Call_GetXssMatchSet_594718; body: JsonNode): Recallable =
  ## getXssMatchSet
  ## Returns the <a>XssMatchSet</a> that is specified by <code>XssMatchSetId</code>.
  ##   body: JObject (required)
  var body_594732 = newJObject()
  if body != nil:
    body_594732 = body
  result = call_594731.call(nil, nil, nil, nil, body_594732)

var getXssMatchSet* = Call_GetXssMatchSet_594718(name: "getXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.GetXssMatchSet",
    validator: validate_GetXssMatchSet_594719, base: "/", url: url_GetXssMatchSet_594720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListActivatedRulesInRuleGroup_594733 = ref object of OpenApiRestCall_593437
proc url_ListActivatedRulesInRuleGroup_594735(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListActivatedRulesInRuleGroup_594734(path: JsonNode; query: JsonNode;
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
  var valid_594736 = header.getOrDefault("X-Amz-Date")
  valid_594736 = validateParameter(valid_594736, JString, required = false,
                                 default = nil)
  if valid_594736 != nil:
    section.add "X-Amz-Date", valid_594736
  var valid_594737 = header.getOrDefault("X-Amz-Security-Token")
  valid_594737 = validateParameter(valid_594737, JString, required = false,
                                 default = nil)
  if valid_594737 != nil:
    section.add "X-Amz-Security-Token", valid_594737
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594738 = header.getOrDefault("X-Amz-Target")
  valid_594738 = validateParameter(valid_594738, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListActivatedRulesInRuleGroup"))
  if valid_594738 != nil:
    section.add "X-Amz-Target", valid_594738
  var valid_594739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594739 = validateParameter(valid_594739, JString, required = false,
                                 default = nil)
  if valid_594739 != nil:
    section.add "X-Amz-Content-Sha256", valid_594739
  var valid_594740 = header.getOrDefault("X-Amz-Algorithm")
  valid_594740 = validateParameter(valid_594740, JString, required = false,
                                 default = nil)
  if valid_594740 != nil:
    section.add "X-Amz-Algorithm", valid_594740
  var valid_594741 = header.getOrDefault("X-Amz-Signature")
  valid_594741 = validateParameter(valid_594741, JString, required = false,
                                 default = nil)
  if valid_594741 != nil:
    section.add "X-Amz-Signature", valid_594741
  var valid_594742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594742 = validateParameter(valid_594742, JString, required = false,
                                 default = nil)
  if valid_594742 != nil:
    section.add "X-Amz-SignedHeaders", valid_594742
  var valid_594743 = header.getOrDefault("X-Amz-Credential")
  valid_594743 = validateParameter(valid_594743, JString, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "X-Amz-Credential", valid_594743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594745: Call_ListActivatedRulesInRuleGroup_594733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>ActivatedRule</a> objects.
  ## 
  let valid = call_594745.validator(path, query, header, formData, body)
  let scheme = call_594745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594745.url(scheme.get, call_594745.host, call_594745.base,
                         call_594745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594745, url, valid)

proc call*(call_594746: Call_ListActivatedRulesInRuleGroup_594733; body: JsonNode): Recallable =
  ## listActivatedRulesInRuleGroup
  ## Returns an array of <a>ActivatedRule</a> objects.
  ##   body: JObject (required)
  var body_594747 = newJObject()
  if body != nil:
    body_594747 = body
  result = call_594746.call(nil, nil, nil, nil, body_594747)

var listActivatedRulesInRuleGroup* = Call_ListActivatedRulesInRuleGroup_594733(
    name: "listActivatedRulesInRuleGroup", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListActivatedRulesInRuleGroup",
    validator: validate_ListActivatedRulesInRuleGroup_594734, base: "/",
    url: url_ListActivatedRulesInRuleGroup_594735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListByteMatchSets_594748 = ref object of OpenApiRestCall_593437
proc url_ListByteMatchSets_594750(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListByteMatchSets_594749(path: JsonNode; query: JsonNode;
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
  var valid_594751 = header.getOrDefault("X-Amz-Date")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Date", valid_594751
  var valid_594752 = header.getOrDefault("X-Amz-Security-Token")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Security-Token", valid_594752
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594753 = header.getOrDefault("X-Amz-Target")
  valid_594753 = validateParameter(valid_594753, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListByteMatchSets"))
  if valid_594753 != nil:
    section.add "X-Amz-Target", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Content-Sha256", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Algorithm")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Algorithm", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-Signature")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-Signature", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-SignedHeaders", valid_594757
  var valid_594758 = header.getOrDefault("X-Amz-Credential")
  valid_594758 = validateParameter(valid_594758, JString, required = false,
                                 default = nil)
  if valid_594758 != nil:
    section.add "X-Amz-Credential", valid_594758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594760: Call_ListByteMatchSets_594748; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>ByteMatchSetSummary</a> objects.
  ## 
  let valid = call_594760.validator(path, query, header, formData, body)
  let scheme = call_594760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594760.url(scheme.get, call_594760.host, call_594760.base,
                         call_594760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594760, url, valid)

proc call*(call_594761: Call_ListByteMatchSets_594748; body: JsonNode): Recallable =
  ## listByteMatchSets
  ## Returns an array of <a>ByteMatchSetSummary</a> objects.
  ##   body: JObject (required)
  var body_594762 = newJObject()
  if body != nil:
    body_594762 = body
  result = call_594761.call(nil, nil, nil, nil, body_594762)

var listByteMatchSets* = Call_ListByteMatchSets_594748(name: "listByteMatchSets",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListByteMatchSets",
    validator: validate_ListByteMatchSets_594749, base: "/",
    url: url_ListByteMatchSets_594750, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGeoMatchSets_594763 = ref object of OpenApiRestCall_593437
proc url_ListGeoMatchSets_594765(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListGeoMatchSets_594764(path: JsonNode; query: JsonNode;
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
  var valid_594766 = header.getOrDefault("X-Amz-Date")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Date", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Security-Token")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Security-Token", valid_594767
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594768 = header.getOrDefault("X-Amz-Target")
  valid_594768 = validateParameter(valid_594768, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListGeoMatchSets"))
  if valid_594768 != nil:
    section.add "X-Amz-Target", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Content-Sha256", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-Algorithm")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Algorithm", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-Signature")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-Signature", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-SignedHeaders", valid_594772
  var valid_594773 = header.getOrDefault("X-Amz-Credential")
  valid_594773 = validateParameter(valid_594773, JString, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "X-Amz-Credential", valid_594773
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594775: Call_ListGeoMatchSets_594763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>GeoMatchSetSummary</a> objects in the response.
  ## 
  let valid = call_594775.validator(path, query, header, formData, body)
  let scheme = call_594775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594775.url(scheme.get, call_594775.host, call_594775.base,
                         call_594775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594775, url, valid)

proc call*(call_594776: Call_ListGeoMatchSets_594763; body: JsonNode): Recallable =
  ## listGeoMatchSets
  ## Returns an array of <a>GeoMatchSetSummary</a> objects in the response.
  ##   body: JObject (required)
  var body_594777 = newJObject()
  if body != nil:
    body_594777 = body
  result = call_594776.call(nil, nil, nil, nil, body_594777)

var listGeoMatchSets* = Call_ListGeoMatchSets_594763(name: "listGeoMatchSets",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListGeoMatchSets",
    validator: validate_ListGeoMatchSets_594764, base: "/",
    url: url_ListGeoMatchSets_594765, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIPSets_594778 = ref object of OpenApiRestCall_593437
proc url_ListIPSets_594780(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListIPSets_594779(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594781 = header.getOrDefault("X-Amz-Date")
  valid_594781 = validateParameter(valid_594781, JString, required = false,
                                 default = nil)
  if valid_594781 != nil:
    section.add "X-Amz-Date", valid_594781
  var valid_594782 = header.getOrDefault("X-Amz-Security-Token")
  valid_594782 = validateParameter(valid_594782, JString, required = false,
                                 default = nil)
  if valid_594782 != nil:
    section.add "X-Amz-Security-Token", valid_594782
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594783 = header.getOrDefault("X-Amz-Target")
  valid_594783 = validateParameter(valid_594783, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListIPSets"))
  if valid_594783 != nil:
    section.add "X-Amz-Target", valid_594783
  var valid_594784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594784 = validateParameter(valid_594784, JString, required = false,
                                 default = nil)
  if valid_594784 != nil:
    section.add "X-Amz-Content-Sha256", valid_594784
  var valid_594785 = header.getOrDefault("X-Amz-Algorithm")
  valid_594785 = validateParameter(valid_594785, JString, required = false,
                                 default = nil)
  if valid_594785 != nil:
    section.add "X-Amz-Algorithm", valid_594785
  var valid_594786 = header.getOrDefault("X-Amz-Signature")
  valid_594786 = validateParameter(valid_594786, JString, required = false,
                                 default = nil)
  if valid_594786 != nil:
    section.add "X-Amz-Signature", valid_594786
  var valid_594787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "X-Amz-SignedHeaders", valid_594787
  var valid_594788 = header.getOrDefault("X-Amz-Credential")
  valid_594788 = validateParameter(valid_594788, JString, required = false,
                                 default = nil)
  if valid_594788 != nil:
    section.add "X-Amz-Credential", valid_594788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594790: Call_ListIPSets_594778; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>IPSetSummary</a> objects in the response.
  ## 
  let valid = call_594790.validator(path, query, header, formData, body)
  let scheme = call_594790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594790.url(scheme.get, call_594790.host, call_594790.base,
                         call_594790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594790, url, valid)

proc call*(call_594791: Call_ListIPSets_594778; body: JsonNode): Recallable =
  ## listIPSets
  ## Returns an array of <a>IPSetSummary</a> objects in the response.
  ##   body: JObject (required)
  var body_594792 = newJObject()
  if body != nil:
    body_594792 = body
  result = call_594791.call(nil, nil, nil, nil, body_594792)

var listIPSets* = Call_ListIPSets_594778(name: "listIPSets",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListIPSets",
                                      validator: validate_ListIPSets_594779,
                                      base: "/", url: url_ListIPSets_594780,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLoggingConfigurations_594793 = ref object of OpenApiRestCall_593437
proc url_ListLoggingConfigurations_594795(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListLoggingConfigurations_594794(path: JsonNode; query: JsonNode;
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
  var valid_594796 = header.getOrDefault("X-Amz-Date")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-Date", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Security-Token")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Security-Token", valid_594797
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594798 = header.getOrDefault("X-Amz-Target")
  valid_594798 = validateParameter(valid_594798, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListLoggingConfigurations"))
  if valid_594798 != nil:
    section.add "X-Amz-Target", valid_594798
  var valid_594799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594799 = validateParameter(valid_594799, JString, required = false,
                                 default = nil)
  if valid_594799 != nil:
    section.add "X-Amz-Content-Sha256", valid_594799
  var valid_594800 = header.getOrDefault("X-Amz-Algorithm")
  valid_594800 = validateParameter(valid_594800, JString, required = false,
                                 default = nil)
  if valid_594800 != nil:
    section.add "X-Amz-Algorithm", valid_594800
  var valid_594801 = header.getOrDefault("X-Amz-Signature")
  valid_594801 = validateParameter(valid_594801, JString, required = false,
                                 default = nil)
  if valid_594801 != nil:
    section.add "X-Amz-Signature", valid_594801
  var valid_594802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594802 = validateParameter(valid_594802, JString, required = false,
                                 default = nil)
  if valid_594802 != nil:
    section.add "X-Amz-SignedHeaders", valid_594802
  var valid_594803 = header.getOrDefault("X-Amz-Credential")
  valid_594803 = validateParameter(valid_594803, JString, required = false,
                                 default = nil)
  if valid_594803 != nil:
    section.add "X-Amz-Credential", valid_594803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594805: Call_ListLoggingConfigurations_594793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>LoggingConfiguration</a> objects.
  ## 
  let valid = call_594805.validator(path, query, header, formData, body)
  let scheme = call_594805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594805.url(scheme.get, call_594805.host, call_594805.base,
                         call_594805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594805, url, valid)

proc call*(call_594806: Call_ListLoggingConfigurations_594793; body: JsonNode): Recallable =
  ## listLoggingConfigurations
  ## Returns an array of <a>LoggingConfiguration</a> objects.
  ##   body: JObject (required)
  var body_594807 = newJObject()
  if body != nil:
    body_594807 = body
  result = call_594806.call(nil, nil, nil, nil, body_594807)

var listLoggingConfigurations* = Call_ListLoggingConfigurations_594793(
    name: "listLoggingConfigurations", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListLoggingConfigurations",
    validator: validate_ListLoggingConfigurations_594794, base: "/",
    url: url_ListLoggingConfigurations_594795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRateBasedRules_594808 = ref object of OpenApiRestCall_593437
proc url_ListRateBasedRules_594810(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRateBasedRules_594809(path: JsonNode; query: JsonNode;
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
  var valid_594811 = header.getOrDefault("X-Amz-Date")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-Date", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Security-Token")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Security-Token", valid_594812
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594813 = header.getOrDefault("X-Amz-Target")
  valid_594813 = validateParameter(valid_594813, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRateBasedRules"))
  if valid_594813 != nil:
    section.add "X-Amz-Target", valid_594813
  var valid_594814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594814 = validateParameter(valid_594814, JString, required = false,
                                 default = nil)
  if valid_594814 != nil:
    section.add "X-Amz-Content-Sha256", valid_594814
  var valid_594815 = header.getOrDefault("X-Amz-Algorithm")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "X-Amz-Algorithm", valid_594815
  var valid_594816 = header.getOrDefault("X-Amz-Signature")
  valid_594816 = validateParameter(valid_594816, JString, required = false,
                                 default = nil)
  if valid_594816 != nil:
    section.add "X-Amz-Signature", valid_594816
  var valid_594817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594817 = validateParameter(valid_594817, JString, required = false,
                                 default = nil)
  if valid_594817 != nil:
    section.add "X-Amz-SignedHeaders", valid_594817
  var valid_594818 = header.getOrDefault("X-Amz-Credential")
  valid_594818 = validateParameter(valid_594818, JString, required = false,
                                 default = nil)
  if valid_594818 != nil:
    section.add "X-Amz-Credential", valid_594818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594820: Call_ListRateBasedRules_594808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleSummary</a> objects.
  ## 
  let valid = call_594820.validator(path, query, header, formData, body)
  let scheme = call_594820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594820.url(scheme.get, call_594820.host, call_594820.base,
                         call_594820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594820, url, valid)

proc call*(call_594821: Call_ListRateBasedRules_594808; body: JsonNode): Recallable =
  ## listRateBasedRules
  ## Returns an array of <a>RuleSummary</a> objects.
  ##   body: JObject (required)
  var body_594822 = newJObject()
  if body != nil:
    body_594822 = body
  result = call_594821.call(nil, nil, nil, nil, body_594822)

var listRateBasedRules* = Call_ListRateBasedRules_594808(
    name: "listRateBasedRules", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRateBasedRules",
    validator: validate_ListRateBasedRules_594809, base: "/",
    url: url_ListRateBasedRules_594810, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegexMatchSets_594823 = ref object of OpenApiRestCall_593437
proc url_ListRegexMatchSets_594825(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRegexMatchSets_594824(path: JsonNode; query: JsonNode;
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
  var valid_594826 = header.getOrDefault("X-Amz-Date")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "X-Amz-Date", valid_594826
  var valid_594827 = header.getOrDefault("X-Amz-Security-Token")
  valid_594827 = validateParameter(valid_594827, JString, required = false,
                                 default = nil)
  if valid_594827 != nil:
    section.add "X-Amz-Security-Token", valid_594827
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594828 = header.getOrDefault("X-Amz-Target")
  valid_594828 = validateParameter(valid_594828, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRegexMatchSets"))
  if valid_594828 != nil:
    section.add "X-Amz-Target", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Content-Sha256", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Algorithm")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Algorithm", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Signature")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Signature", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-SignedHeaders", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-Credential")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-Credential", valid_594833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594835: Call_ListRegexMatchSets_594823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RegexMatchSetSummary</a> objects.
  ## 
  let valid = call_594835.validator(path, query, header, formData, body)
  let scheme = call_594835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594835.url(scheme.get, call_594835.host, call_594835.base,
                         call_594835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594835, url, valid)

proc call*(call_594836: Call_ListRegexMatchSets_594823; body: JsonNode): Recallable =
  ## listRegexMatchSets
  ## Returns an array of <a>RegexMatchSetSummary</a> objects.
  ##   body: JObject (required)
  var body_594837 = newJObject()
  if body != nil:
    body_594837 = body
  result = call_594836.call(nil, nil, nil, nil, body_594837)

var listRegexMatchSets* = Call_ListRegexMatchSets_594823(
    name: "listRegexMatchSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRegexMatchSets",
    validator: validate_ListRegexMatchSets_594824, base: "/",
    url: url_ListRegexMatchSets_594825, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRegexPatternSets_594838 = ref object of OpenApiRestCall_593437
proc url_ListRegexPatternSets_594840(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRegexPatternSets_594839(path: JsonNode; query: JsonNode;
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
  var valid_594841 = header.getOrDefault("X-Amz-Date")
  valid_594841 = validateParameter(valid_594841, JString, required = false,
                                 default = nil)
  if valid_594841 != nil:
    section.add "X-Amz-Date", valid_594841
  var valid_594842 = header.getOrDefault("X-Amz-Security-Token")
  valid_594842 = validateParameter(valid_594842, JString, required = false,
                                 default = nil)
  if valid_594842 != nil:
    section.add "X-Amz-Security-Token", valid_594842
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594843 = header.getOrDefault("X-Amz-Target")
  valid_594843 = validateParameter(valid_594843, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRegexPatternSets"))
  if valid_594843 != nil:
    section.add "X-Amz-Target", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Content-Sha256", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Algorithm")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Algorithm", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Signature")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Signature", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-SignedHeaders", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-Credential")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-Credential", valid_594848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594850: Call_ListRegexPatternSets_594838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RegexPatternSetSummary</a> objects.
  ## 
  let valid = call_594850.validator(path, query, header, formData, body)
  let scheme = call_594850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594850.url(scheme.get, call_594850.host, call_594850.base,
                         call_594850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594850, url, valid)

proc call*(call_594851: Call_ListRegexPatternSets_594838; body: JsonNode): Recallable =
  ## listRegexPatternSets
  ## Returns an array of <a>RegexPatternSetSummary</a> objects.
  ##   body: JObject (required)
  var body_594852 = newJObject()
  if body != nil:
    body_594852 = body
  result = call_594851.call(nil, nil, nil, nil, body_594852)

var listRegexPatternSets* = Call_ListRegexPatternSets_594838(
    name: "listRegexPatternSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRegexPatternSets",
    validator: validate_ListRegexPatternSets_594839, base: "/",
    url: url_ListRegexPatternSets_594840, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourcesForWebACL_594853 = ref object of OpenApiRestCall_593437
proc url_ListResourcesForWebACL_594855(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListResourcesForWebACL_594854(path: JsonNode; query: JsonNode;
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
  var valid_594856 = header.getOrDefault("X-Amz-Date")
  valid_594856 = validateParameter(valid_594856, JString, required = false,
                                 default = nil)
  if valid_594856 != nil:
    section.add "X-Amz-Date", valid_594856
  var valid_594857 = header.getOrDefault("X-Amz-Security-Token")
  valid_594857 = validateParameter(valid_594857, JString, required = false,
                                 default = nil)
  if valid_594857 != nil:
    section.add "X-Amz-Security-Token", valid_594857
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594858 = header.getOrDefault("X-Amz-Target")
  valid_594858 = validateParameter(valid_594858, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListResourcesForWebACL"))
  if valid_594858 != nil:
    section.add "X-Amz-Target", valid_594858
  var valid_594859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594859 = validateParameter(valid_594859, JString, required = false,
                                 default = nil)
  if valid_594859 != nil:
    section.add "X-Amz-Content-Sha256", valid_594859
  var valid_594860 = header.getOrDefault("X-Amz-Algorithm")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "X-Amz-Algorithm", valid_594860
  var valid_594861 = header.getOrDefault("X-Amz-Signature")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "X-Amz-Signature", valid_594861
  var valid_594862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594862 = validateParameter(valid_594862, JString, required = false,
                                 default = nil)
  if valid_594862 != nil:
    section.add "X-Amz-SignedHeaders", valid_594862
  var valid_594863 = header.getOrDefault("X-Amz-Credential")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "X-Amz-Credential", valid_594863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594865: Call_ListResourcesForWebACL_594853; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of resources associated with the specified web ACL.
  ## 
  let valid = call_594865.validator(path, query, header, formData, body)
  let scheme = call_594865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594865.url(scheme.get, call_594865.host, call_594865.base,
                         call_594865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594865, url, valid)

proc call*(call_594866: Call_ListResourcesForWebACL_594853; body: JsonNode): Recallable =
  ## listResourcesForWebACL
  ## Returns an array of resources associated with the specified web ACL.
  ##   body: JObject (required)
  var body_594867 = newJObject()
  if body != nil:
    body_594867 = body
  result = call_594866.call(nil, nil, nil, nil, body_594867)

var listResourcesForWebACL* = Call_ListResourcesForWebACL_594853(
    name: "listResourcesForWebACL", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListResourcesForWebACL",
    validator: validate_ListResourcesForWebACL_594854, base: "/",
    url: url_ListResourcesForWebACL_594855, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRuleGroups_594868 = ref object of OpenApiRestCall_593437
proc url_ListRuleGroups_594870(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRuleGroups_594869(path: JsonNode; query: JsonNode;
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
  var valid_594871 = header.getOrDefault("X-Amz-Date")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-Date", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-Security-Token")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Security-Token", valid_594872
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594873 = header.getOrDefault("X-Amz-Target")
  valid_594873 = validateParameter(valid_594873, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRuleGroups"))
  if valid_594873 != nil:
    section.add "X-Amz-Target", valid_594873
  var valid_594874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594874 = validateParameter(valid_594874, JString, required = false,
                                 default = nil)
  if valid_594874 != nil:
    section.add "X-Amz-Content-Sha256", valid_594874
  var valid_594875 = header.getOrDefault("X-Amz-Algorithm")
  valid_594875 = validateParameter(valid_594875, JString, required = false,
                                 default = nil)
  if valid_594875 != nil:
    section.add "X-Amz-Algorithm", valid_594875
  var valid_594876 = header.getOrDefault("X-Amz-Signature")
  valid_594876 = validateParameter(valid_594876, JString, required = false,
                                 default = nil)
  if valid_594876 != nil:
    section.add "X-Amz-Signature", valid_594876
  var valid_594877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594877 = validateParameter(valid_594877, JString, required = false,
                                 default = nil)
  if valid_594877 != nil:
    section.add "X-Amz-SignedHeaders", valid_594877
  var valid_594878 = header.getOrDefault("X-Amz-Credential")
  valid_594878 = validateParameter(valid_594878, JString, required = false,
                                 default = nil)
  if valid_594878 != nil:
    section.add "X-Amz-Credential", valid_594878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594880: Call_ListRuleGroups_594868; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleGroup</a> objects.
  ## 
  let valid = call_594880.validator(path, query, header, formData, body)
  let scheme = call_594880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594880.url(scheme.get, call_594880.host, call_594880.base,
                         call_594880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594880, url, valid)

proc call*(call_594881: Call_ListRuleGroups_594868; body: JsonNode): Recallable =
  ## listRuleGroups
  ## Returns an array of <a>RuleGroup</a> objects.
  ##   body: JObject (required)
  var body_594882 = newJObject()
  if body != nil:
    body_594882 = body
  result = call_594881.call(nil, nil, nil, nil, body_594882)

var listRuleGroups* = Call_ListRuleGroups_594868(name: "listRuleGroups",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRuleGroups",
    validator: validate_ListRuleGroups_594869, base: "/", url: url_ListRuleGroups_594870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRules_594883 = ref object of OpenApiRestCall_593437
proc url_ListRules_594885(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRules_594884(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594886 = header.getOrDefault("X-Amz-Date")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-Date", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Security-Token")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Security-Token", valid_594887
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594888 = header.getOrDefault("X-Amz-Target")
  valid_594888 = validateParameter(valid_594888, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListRules"))
  if valid_594888 != nil:
    section.add "X-Amz-Target", valid_594888
  var valid_594889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "X-Amz-Content-Sha256", valid_594889
  var valid_594890 = header.getOrDefault("X-Amz-Algorithm")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "X-Amz-Algorithm", valid_594890
  var valid_594891 = header.getOrDefault("X-Amz-Signature")
  valid_594891 = validateParameter(valid_594891, JString, required = false,
                                 default = nil)
  if valid_594891 != nil:
    section.add "X-Amz-Signature", valid_594891
  var valid_594892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594892 = validateParameter(valid_594892, JString, required = false,
                                 default = nil)
  if valid_594892 != nil:
    section.add "X-Amz-SignedHeaders", valid_594892
  var valid_594893 = header.getOrDefault("X-Amz-Credential")
  valid_594893 = validateParameter(valid_594893, JString, required = false,
                                 default = nil)
  if valid_594893 != nil:
    section.add "X-Amz-Credential", valid_594893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594895: Call_ListRules_594883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleSummary</a> objects.
  ## 
  let valid = call_594895.validator(path, query, header, formData, body)
  let scheme = call_594895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594895.url(scheme.get, call_594895.host, call_594895.base,
                         call_594895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594895, url, valid)

proc call*(call_594896: Call_ListRules_594883; body: JsonNode): Recallable =
  ## listRules
  ## Returns an array of <a>RuleSummary</a> objects.
  ##   body: JObject (required)
  var body_594897 = newJObject()
  if body != nil:
    body_594897 = body
  result = call_594896.call(nil, nil, nil, nil, body_594897)

var listRules* = Call_ListRules_594883(name: "listRules", meth: HttpMethod.HttpPost,
                                    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListRules",
                                    validator: validate_ListRules_594884,
                                    base: "/", url: url_ListRules_594885,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSizeConstraintSets_594898 = ref object of OpenApiRestCall_593437
proc url_ListSizeConstraintSets_594900(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSizeConstraintSets_594899(path: JsonNode; query: JsonNode;
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
  var valid_594901 = header.getOrDefault("X-Amz-Date")
  valid_594901 = validateParameter(valid_594901, JString, required = false,
                                 default = nil)
  if valid_594901 != nil:
    section.add "X-Amz-Date", valid_594901
  var valid_594902 = header.getOrDefault("X-Amz-Security-Token")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "X-Amz-Security-Token", valid_594902
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594903 = header.getOrDefault("X-Amz-Target")
  valid_594903 = validateParameter(valid_594903, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListSizeConstraintSets"))
  if valid_594903 != nil:
    section.add "X-Amz-Target", valid_594903
  var valid_594904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "X-Amz-Content-Sha256", valid_594904
  var valid_594905 = header.getOrDefault("X-Amz-Algorithm")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Algorithm", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Signature")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Signature", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-SignedHeaders", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Credential")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Credential", valid_594908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594910: Call_ListSizeConstraintSets_594898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>SizeConstraintSetSummary</a> objects.
  ## 
  let valid = call_594910.validator(path, query, header, formData, body)
  let scheme = call_594910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594910.url(scheme.get, call_594910.host, call_594910.base,
                         call_594910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594910, url, valid)

proc call*(call_594911: Call_ListSizeConstraintSets_594898; body: JsonNode): Recallable =
  ## listSizeConstraintSets
  ## Returns an array of <a>SizeConstraintSetSummary</a> objects.
  ##   body: JObject (required)
  var body_594912 = newJObject()
  if body != nil:
    body_594912 = body
  result = call_594911.call(nil, nil, nil, nil, body_594912)

var listSizeConstraintSets* = Call_ListSizeConstraintSets_594898(
    name: "listSizeConstraintSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListSizeConstraintSets",
    validator: validate_ListSizeConstraintSets_594899, base: "/",
    url: url_ListSizeConstraintSets_594900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSqlInjectionMatchSets_594913 = ref object of OpenApiRestCall_593437
proc url_ListSqlInjectionMatchSets_594915(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSqlInjectionMatchSets_594914(path: JsonNode; query: JsonNode;
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
  var valid_594916 = header.getOrDefault("X-Amz-Date")
  valid_594916 = validateParameter(valid_594916, JString, required = false,
                                 default = nil)
  if valid_594916 != nil:
    section.add "X-Amz-Date", valid_594916
  var valid_594917 = header.getOrDefault("X-Amz-Security-Token")
  valid_594917 = validateParameter(valid_594917, JString, required = false,
                                 default = nil)
  if valid_594917 != nil:
    section.add "X-Amz-Security-Token", valid_594917
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594918 = header.getOrDefault("X-Amz-Target")
  valid_594918 = validateParameter(valid_594918, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListSqlInjectionMatchSets"))
  if valid_594918 != nil:
    section.add "X-Amz-Target", valid_594918
  var valid_594919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Content-Sha256", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Algorithm")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Algorithm", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Signature")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Signature", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-SignedHeaders", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Credential")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Credential", valid_594923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594925: Call_ListSqlInjectionMatchSets_594913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>SqlInjectionMatchSet</a> objects.
  ## 
  let valid = call_594925.validator(path, query, header, formData, body)
  let scheme = call_594925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594925.url(scheme.get, call_594925.host, call_594925.base,
                         call_594925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594925, url, valid)

proc call*(call_594926: Call_ListSqlInjectionMatchSets_594913; body: JsonNode): Recallable =
  ## listSqlInjectionMatchSets
  ## Returns an array of <a>SqlInjectionMatchSet</a> objects.
  ##   body: JObject (required)
  var body_594927 = newJObject()
  if body != nil:
    body_594927 = body
  result = call_594926.call(nil, nil, nil, nil, body_594927)

var listSqlInjectionMatchSets* = Call_ListSqlInjectionMatchSets_594913(
    name: "listSqlInjectionMatchSets", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListSqlInjectionMatchSets",
    validator: validate_ListSqlInjectionMatchSets_594914, base: "/",
    url: url_ListSqlInjectionMatchSets_594915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSubscribedRuleGroups_594928 = ref object of OpenApiRestCall_593437
proc url_ListSubscribedRuleGroups_594930(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSubscribedRuleGroups_594929(path: JsonNode; query: JsonNode;
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
  var valid_594931 = header.getOrDefault("X-Amz-Date")
  valid_594931 = validateParameter(valid_594931, JString, required = false,
                                 default = nil)
  if valid_594931 != nil:
    section.add "X-Amz-Date", valid_594931
  var valid_594932 = header.getOrDefault("X-Amz-Security-Token")
  valid_594932 = validateParameter(valid_594932, JString, required = false,
                                 default = nil)
  if valid_594932 != nil:
    section.add "X-Amz-Security-Token", valid_594932
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594933 = header.getOrDefault("X-Amz-Target")
  valid_594933 = validateParameter(valid_594933, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListSubscribedRuleGroups"))
  if valid_594933 != nil:
    section.add "X-Amz-Target", valid_594933
  var valid_594934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594934 = validateParameter(valid_594934, JString, required = false,
                                 default = nil)
  if valid_594934 != nil:
    section.add "X-Amz-Content-Sha256", valid_594934
  var valid_594935 = header.getOrDefault("X-Amz-Algorithm")
  valid_594935 = validateParameter(valid_594935, JString, required = false,
                                 default = nil)
  if valid_594935 != nil:
    section.add "X-Amz-Algorithm", valid_594935
  var valid_594936 = header.getOrDefault("X-Amz-Signature")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "X-Amz-Signature", valid_594936
  var valid_594937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594937 = validateParameter(valid_594937, JString, required = false,
                                 default = nil)
  if valid_594937 != nil:
    section.add "X-Amz-SignedHeaders", valid_594937
  var valid_594938 = header.getOrDefault("X-Amz-Credential")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "X-Amz-Credential", valid_594938
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594940: Call_ListSubscribedRuleGroups_594928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>RuleGroup</a> objects that you are subscribed to.
  ## 
  let valid = call_594940.validator(path, query, header, formData, body)
  let scheme = call_594940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594940.url(scheme.get, call_594940.host, call_594940.base,
                         call_594940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594940, url, valid)

proc call*(call_594941: Call_ListSubscribedRuleGroups_594928; body: JsonNode): Recallable =
  ## listSubscribedRuleGroups
  ## Returns an array of <a>RuleGroup</a> objects that you are subscribed to.
  ##   body: JObject (required)
  var body_594942 = newJObject()
  if body != nil:
    body_594942 = body
  result = call_594941.call(nil, nil, nil, nil, body_594942)

var listSubscribedRuleGroups* = Call_ListSubscribedRuleGroups_594928(
    name: "listSubscribedRuleGroups", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListSubscribedRuleGroups",
    validator: validate_ListSubscribedRuleGroups_594929, base: "/",
    url: url_ListSubscribedRuleGroups_594930, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594943 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594945(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_594944(path: JsonNode; query: JsonNode;
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
  var valid_594946 = header.getOrDefault("X-Amz-Date")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-Date", valid_594946
  var valid_594947 = header.getOrDefault("X-Amz-Security-Token")
  valid_594947 = validateParameter(valid_594947, JString, required = false,
                                 default = nil)
  if valid_594947 != nil:
    section.add "X-Amz-Security-Token", valid_594947
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594948 = header.getOrDefault("X-Amz-Target")
  valid_594948 = validateParameter(valid_594948, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListTagsForResource"))
  if valid_594948 != nil:
    section.add "X-Amz-Target", valid_594948
  var valid_594949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594949 = validateParameter(valid_594949, JString, required = false,
                                 default = nil)
  if valid_594949 != nil:
    section.add "X-Amz-Content-Sha256", valid_594949
  var valid_594950 = header.getOrDefault("X-Amz-Algorithm")
  valid_594950 = validateParameter(valid_594950, JString, required = false,
                                 default = nil)
  if valid_594950 != nil:
    section.add "X-Amz-Algorithm", valid_594950
  var valid_594951 = header.getOrDefault("X-Amz-Signature")
  valid_594951 = validateParameter(valid_594951, JString, required = false,
                                 default = nil)
  if valid_594951 != nil:
    section.add "X-Amz-Signature", valid_594951
  var valid_594952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594952 = validateParameter(valid_594952, JString, required = false,
                                 default = nil)
  if valid_594952 != nil:
    section.add "X-Amz-SignedHeaders", valid_594952
  var valid_594953 = header.getOrDefault("X-Amz-Credential")
  valid_594953 = validateParameter(valid_594953, JString, required = false,
                                 default = nil)
  if valid_594953 != nil:
    section.add "X-Amz-Credential", valid_594953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594955: Call_ListTagsForResource_594943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_594955.validator(path, query, header, formData, body)
  let scheme = call_594955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594955.url(scheme.get, call_594955.host, call_594955.base,
                         call_594955.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594955, url, valid)

proc call*(call_594956: Call_ListTagsForResource_594943; body: JsonNode): Recallable =
  ## listTagsForResource
  ##   body: JObject (required)
  var body_594957 = newJObject()
  if body != nil:
    body_594957 = body
  result = call_594956.call(nil, nil, nil, nil, body_594957)

var listTagsForResource* = Call_ListTagsForResource_594943(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListTagsForResource",
    validator: validate_ListTagsForResource_594944, base: "/",
    url: url_ListTagsForResource_594945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListWebACLs_594958 = ref object of OpenApiRestCall_593437
proc url_ListWebACLs_594960(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListWebACLs_594959(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594961 = header.getOrDefault("X-Amz-Date")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Date", valid_594961
  var valid_594962 = header.getOrDefault("X-Amz-Security-Token")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "X-Amz-Security-Token", valid_594962
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594963 = header.getOrDefault("X-Amz-Target")
  valid_594963 = validateParameter(valid_594963, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListWebACLs"))
  if valid_594963 != nil:
    section.add "X-Amz-Target", valid_594963
  var valid_594964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594964 = validateParameter(valid_594964, JString, required = false,
                                 default = nil)
  if valid_594964 != nil:
    section.add "X-Amz-Content-Sha256", valid_594964
  var valid_594965 = header.getOrDefault("X-Amz-Algorithm")
  valid_594965 = validateParameter(valid_594965, JString, required = false,
                                 default = nil)
  if valid_594965 != nil:
    section.add "X-Amz-Algorithm", valid_594965
  var valid_594966 = header.getOrDefault("X-Amz-Signature")
  valid_594966 = validateParameter(valid_594966, JString, required = false,
                                 default = nil)
  if valid_594966 != nil:
    section.add "X-Amz-Signature", valid_594966
  var valid_594967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594967 = validateParameter(valid_594967, JString, required = false,
                                 default = nil)
  if valid_594967 != nil:
    section.add "X-Amz-SignedHeaders", valid_594967
  var valid_594968 = header.getOrDefault("X-Amz-Credential")
  valid_594968 = validateParameter(valid_594968, JString, required = false,
                                 default = nil)
  if valid_594968 != nil:
    section.add "X-Amz-Credential", valid_594968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594970: Call_ListWebACLs_594958; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>WebACLSummary</a> objects in the response.
  ## 
  let valid = call_594970.validator(path, query, header, formData, body)
  let scheme = call_594970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594970.url(scheme.get, call_594970.host, call_594970.base,
                         call_594970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594970, url, valid)

proc call*(call_594971: Call_ListWebACLs_594958; body: JsonNode): Recallable =
  ## listWebACLs
  ## Returns an array of <a>WebACLSummary</a> objects in the response.
  ##   body: JObject (required)
  var body_594972 = newJObject()
  if body != nil:
    body_594972 = body
  result = call_594971.call(nil, nil, nil, nil, body_594972)

var listWebACLs* = Call_ListWebACLs_594958(name: "listWebACLs",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListWebACLs",
                                        validator: validate_ListWebACLs_594959,
                                        base: "/", url: url_ListWebACLs_594960,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListXssMatchSets_594973 = ref object of OpenApiRestCall_593437
proc url_ListXssMatchSets_594975(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListXssMatchSets_594974(path: JsonNode; query: JsonNode;
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
  var valid_594976 = header.getOrDefault("X-Amz-Date")
  valid_594976 = validateParameter(valid_594976, JString, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "X-Amz-Date", valid_594976
  var valid_594977 = header.getOrDefault("X-Amz-Security-Token")
  valid_594977 = validateParameter(valid_594977, JString, required = false,
                                 default = nil)
  if valid_594977 != nil:
    section.add "X-Amz-Security-Token", valid_594977
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594978 = header.getOrDefault("X-Amz-Target")
  valid_594978 = validateParameter(valid_594978, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.ListXssMatchSets"))
  if valid_594978 != nil:
    section.add "X-Amz-Target", valid_594978
  var valid_594979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594979 = validateParameter(valid_594979, JString, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "X-Amz-Content-Sha256", valid_594979
  var valid_594980 = header.getOrDefault("X-Amz-Algorithm")
  valid_594980 = validateParameter(valid_594980, JString, required = false,
                                 default = nil)
  if valid_594980 != nil:
    section.add "X-Amz-Algorithm", valid_594980
  var valid_594981 = header.getOrDefault("X-Amz-Signature")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-Signature", valid_594981
  var valid_594982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594982 = validateParameter(valid_594982, JString, required = false,
                                 default = nil)
  if valid_594982 != nil:
    section.add "X-Amz-SignedHeaders", valid_594982
  var valid_594983 = header.getOrDefault("X-Amz-Credential")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "X-Amz-Credential", valid_594983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594985: Call_ListXssMatchSets_594973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an array of <a>XssMatchSet</a> objects.
  ## 
  let valid = call_594985.validator(path, query, header, formData, body)
  let scheme = call_594985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594985.url(scheme.get, call_594985.host, call_594985.base,
                         call_594985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594985, url, valid)

proc call*(call_594986: Call_ListXssMatchSets_594973; body: JsonNode): Recallable =
  ## listXssMatchSets
  ## Returns an array of <a>XssMatchSet</a> objects.
  ##   body: JObject (required)
  var body_594987 = newJObject()
  if body != nil:
    body_594987 = body
  result = call_594986.call(nil, nil, nil, nil, body_594987)

var listXssMatchSets* = Call_ListXssMatchSets_594973(name: "listXssMatchSets",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.ListXssMatchSets",
    validator: validate_ListXssMatchSets_594974, base: "/",
    url: url_ListXssMatchSets_594975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLoggingConfiguration_594988 = ref object of OpenApiRestCall_593437
proc url_PutLoggingConfiguration_594990(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutLoggingConfiguration_594989(path: JsonNode; query: JsonNode;
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
  var valid_594991 = header.getOrDefault("X-Amz-Date")
  valid_594991 = validateParameter(valid_594991, JString, required = false,
                                 default = nil)
  if valid_594991 != nil:
    section.add "X-Amz-Date", valid_594991
  var valid_594992 = header.getOrDefault("X-Amz-Security-Token")
  valid_594992 = validateParameter(valid_594992, JString, required = false,
                                 default = nil)
  if valid_594992 != nil:
    section.add "X-Amz-Security-Token", valid_594992
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_594993 = header.getOrDefault("X-Amz-Target")
  valid_594993 = validateParameter(valid_594993, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.PutLoggingConfiguration"))
  if valid_594993 != nil:
    section.add "X-Amz-Target", valid_594993
  var valid_594994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594994 = validateParameter(valid_594994, JString, required = false,
                                 default = nil)
  if valid_594994 != nil:
    section.add "X-Amz-Content-Sha256", valid_594994
  var valid_594995 = header.getOrDefault("X-Amz-Algorithm")
  valid_594995 = validateParameter(valid_594995, JString, required = false,
                                 default = nil)
  if valid_594995 != nil:
    section.add "X-Amz-Algorithm", valid_594995
  var valid_594996 = header.getOrDefault("X-Amz-Signature")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Signature", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-SignedHeaders", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Credential")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Credential", valid_594998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595000: Call_PutLoggingConfiguration_594988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Associates a <a>LoggingConfiguration</a> with a specified web ACL.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. However, if you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
  ## 
  let valid = call_595000.validator(path, query, header, formData, body)
  let scheme = call_595000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595000.url(scheme.get, call_595000.host, call_595000.base,
                         call_595000.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595000, url, valid)

proc call*(call_595001: Call_PutLoggingConfiguration_594988; body: JsonNode): Recallable =
  ## putLoggingConfiguration
  ## <p>Associates a <a>LoggingConfiguration</a> with a specified web ACL.</p> <p>You can access information about all traffic that AWS WAF inspects using the following steps:</p> <ol> <li> <p>Create an Amazon Kinesis Data Firehose. </p> <p>Create the data firehose with a PUT source and in the region that you are operating. However, if you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). </p> <note> <p>Do not create the data firehose using a <code>Kinesis stream</code> as your source.</p> </note> </li> <li> <p>Associate that firehose to your web ACL using a <code>PutLoggingConfiguration</code> request.</p> </li> </ol> <p>When you successfully enable logging using a <code>PutLoggingConfiguration</code> request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see <a href="https://docs.aws.amazon.com/waf/latest/developerguide/logging.html">Logging Web ACL Traffic Information</a> in the <i>AWS WAF Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_595002 = newJObject()
  if body != nil:
    body_595002 = body
  result = call_595001.call(nil, nil, nil, nil, body_595002)

var putLoggingConfiguration* = Call_PutLoggingConfiguration_594988(
    name: "putLoggingConfiguration", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.PutLoggingConfiguration",
    validator: validate_PutLoggingConfiguration_594989, base: "/",
    url: url_PutLoggingConfiguration_594990, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutPermissionPolicy_595003 = ref object of OpenApiRestCall_593437
proc url_PutPermissionPolicy_595005(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutPermissionPolicy_595004(path: JsonNode; query: JsonNode;
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
  var valid_595006 = header.getOrDefault("X-Amz-Date")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "X-Amz-Date", valid_595006
  var valid_595007 = header.getOrDefault("X-Amz-Security-Token")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "X-Amz-Security-Token", valid_595007
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595008 = header.getOrDefault("X-Amz-Target")
  valid_595008 = validateParameter(valid_595008, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.PutPermissionPolicy"))
  if valid_595008 != nil:
    section.add "X-Amz-Target", valid_595008
  var valid_595009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595009 = validateParameter(valid_595009, JString, required = false,
                                 default = nil)
  if valid_595009 != nil:
    section.add "X-Amz-Content-Sha256", valid_595009
  var valid_595010 = header.getOrDefault("X-Amz-Algorithm")
  valid_595010 = validateParameter(valid_595010, JString, required = false,
                                 default = nil)
  if valid_595010 != nil:
    section.add "X-Amz-Algorithm", valid_595010
  var valid_595011 = header.getOrDefault("X-Amz-Signature")
  valid_595011 = validateParameter(valid_595011, JString, required = false,
                                 default = nil)
  if valid_595011 != nil:
    section.add "X-Amz-Signature", valid_595011
  var valid_595012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595012 = validateParameter(valid_595012, JString, required = false,
                                 default = nil)
  if valid_595012 != nil:
    section.add "X-Amz-SignedHeaders", valid_595012
  var valid_595013 = header.getOrDefault("X-Amz-Credential")
  valid_595013 = validateParameter(valid_595013, JString, required = false,
                                 default = nil)
  if valid_595013 != nil:
    section.add "X-Amz-Credential", valid_595013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595015: Call_PutPermissionPolicy_595003; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Attaches a IAM policy to the specified resource. The only supported use for this action is to share a RuleGroup across accounts.</p> <p>The <code>PutPermissionPolicy</code> is subject to the following restrictions:</p> <ul> <li> <p>You can attach only one policy with each <code>PutPermissionPolicy</code> request.</p> </li> <li> <p>The policy must include an <code>Effect</code>, <code>Action</code> and <code>Principal</code>. </p> </li> <li> <p> <code>Effect</code> must specify <code>Allow</code>.</p> </li> <li> <p>The <code>Action</code> in the policy must be <code>waf:UpdateWebACL</code>, <code>waf-regional:UpdateWebACL</code>, <code>waf:GetRuleGroup</code> and <code>waf-regional:GetRuleGroup</code> . Any extra or wildcard actions in the policy will be rejected.</p> </li> <li> <p>The policy cannot include a <code>Resource</code> parameter.</p> </li> <li> <p>The ARN in the request must be a valid WAF RuleGroup ARN and the RuleGroup must exist in the same region.</p> </li> <li> <p>The user making the request must be the owner of the RuleGroup.</p> </li> <li> <p>Your policy must be composed using IAM Policy version 2012-10-17.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a>. </p> <p>An example of a valid policy parameter is shown in the Examples section below.</p>
  ## 
  let valid = call_595015.validator(path, query, header, formData, body)
  let scheme = call_595015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595015.url(scheme.get, call_595015.host, call_595015.base,
                         call_595015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595015, url, valid)

proc call*(call_595016: Call_PutPermissionPolicy_595003; body: JsonNode): Recallable =
  ## putPermissionPolicy
  ## <p>Attaches a IAM policy to the specified resource. The only supported use for this action is to share a RuleGroup across accounts.</p> <p>The <code>PutPermissionPolicy</code> is subject to the following restrictions:</p> <ul> <li> <p>You can attach only one policy with each <code>PutPermissionPolicy</code> request.</p> </li> <li> <p>The policy must include an <code>Effect</code>, <code>Action</code> and <code>Principal</code>. </p> </li> <li> <p> <code>Effect</code> must specify <code>Allow</code>.</p> </li> <li> <p>The <code>Action</code> in the policy must be <code>waf:UpdateWebACL</code>, <code>waf-regional:UpdateWebACL</code>, <code>waf:GetRuleGroup</code> and <code>waf-regional:GetRuleGroup</code> . Any extra or wildcard actions in the policy will be rejected.</p> </li> <li> <p>The policy cannot include a <code>Resource</code> parameter.</p> </li> <li> <p>The ARN in the request must be a valid WAF RuleGroup ARN and the RuleGroup must exist in the same region.</p> </li> <li> <p>The user making the request must be the owner of the RuleGroup.</p> </li> <li> <p>Your policy must be composed using IAM Policy version 2012-10-17.</p> </li> </ul> <p>For more information, see <a href="https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html">IAM Policies</a>. </p> <p>An example of a valid policy parameter is shown in the Examples section below.</p>
  ##   body: JObject (required)
  var body_595017 = newJObject()
  if body != nil:
    body_595017 = body
  result = call_595016.call(nil, nil, nil, nil, body_595017)

var putPermissionPolicy* = Call_PutPermissionPolicy_595003(
    name: "putPermissionPolicy", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.PutPermissionPolicy",
    validator: validate_PutPermissionPolicy_595004, base: "/",
    url: url_PutPermissionPolicy_595005, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_595018 = ref object of OpenApiRestCall_593437
proc url_TagResource_595020(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_595019(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595021 = header.getOrDefault("X-Amz-Date")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "X-Amz-Date", valid_595021
  var valid_595022 = header.getOrDefault("X-Amz-Security-Token")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "X-Amz-Security-Token", valid_595022
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595023 = header.getOrDefault("X-Amz-Target")
  valid_595023 = validateParameter(valid_595023, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.TagResource"))
  if valid_595023 != nil:
    section.add "X-Amz-Target", valid_595023
  var valid_595024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "X-Amz-Content-Sha256", valid_595024
  var valid_595025 = header.getOrDefault("X-Amz-Algorithm")
  valid_595025 = validateParameter(valid_595025, JString, required = false,
                                 default = nil)
  if valid_595025 != nil:
    section.add "X-Amz-Algorithm", valid_595025
  var valid_595026 = header.getOrDefault("X-Amz-Signature")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "X-Amz-Signature", valid_595026
  var valid_595027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "X-Amz-SignedHeaders", valid_595027
  var valid_595028 = header.getOrDefault("X-Amz-Credential")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = nil)
  if valid_595028 != nil:
    section.add "X-Amz-Credential", valid_595028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595030: Call_TagResource_595018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595030.validator(path, query, header, formData, body)
  let scheme = call_595030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595030.url(scheme.get, call_595030.host, call_595030.base,
                         call_595030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595030, url, valid)

proc call*(call_595031: Call_TagResource_595018; body: JsonNode): Recallable =
  ## tagResource
  ##   body: JObject (required)
  var body_595032 = newJObject()
  if body != nil:
    body_595032 = body
  result = call_595031.call(nil, nil, nil, nil, body_595032)

var tagResource* = Call_TagResource_595018(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.TagResource",
                                        validator: validate_TagResource_595019,
                                        base: "/", url: url_TagResource_595020,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_595033 = ref object of OpenApiRestCall_593437
proc url_UntagResource_595035(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_595034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595036 = header.getOrDefault("X-Amz-Date")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Date", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-Security-Token")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-Security-Token", valid_595037
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595038 = header.getOrDefault("X-Amz-Target")
  valid_595038 = validateParameter(valid_595038, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UntagResource"))
  if valid_595038 != nil:
    section.add "X-Amz-Target", valid_595038
  var valid_595039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595039 = validateParameter(valid_595039, JString, required = false,
                                 default = nil)
  if valid_595039 != nil:
    section.add "X-Amz-Content-Sha256", valid_595039
  var valid_595040 = header.getOrDefault("X-Amz-Algorithm")
  valid_595040 = validateParameter(valid_595040, JString, required = false,
                                 default = nil)
  if valid_595040 != nil:
    section.add "X-Amz-Algorithm", valid_595040
  var valid_595041 = header.getOrDefault("X-Amz-Signature")
  valid_595041 = validateParameter(valid_595041, JString, required = false,
                                 default = nil)
  if valid_595041 != nil:
    section.add "X-Amz-Signature", valid_595041
  var valid_595042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595042 = validateParameter(valid_595042, JString, required = false,
                                 default = nil)
  if valid_595042 != nil:
    section.add "X-Amz-SignedHeaders", valid_595042
  var valid_595043 = header.getOrDefault("X-Amz-Credential")
  valid_595043 = validateParameter(valid_595043, JString, required = false,
                                 default = nil)
  if valid_595043 != nil:
    section.add "X-Amz-Credential", valid_595043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595045: Call_UntagResource_595033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_595045.validator(path, query, header, formData, body)
  let scheme = call_595045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595045.url(scheme.get, call_595045.host, call_595045.base,
                         call_595045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595045, url, valid)

proc call*(call_595046: Call_UntagResource_595033; body: JsonNode): Recallable =
  ## untagResource
  ##   body: JObject (required)
  var body_595047 = newJObject()
  if body != nil:
    body_595047 = body
  result = call_595046.call(nil, nil, nil, nil, body_595047)

var untagResource* = Call_UntagResource_595033(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UntagResource",
    validator: validate_UntagResource_595034, base: "/", url: url_UntagResource_595035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateByteMatchSet_595048 = ref object of OpenApiRestCall_593437
proc url_UpdateByteMatchSet_595050(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateByteMatchSet_595049(path: JsonNode; query: JsonNode;
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
  var valid_595051 = header.getOrDefault("X-Amz-Date")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Date", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-Security-Token")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-Security-Token", valid_595052
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595053 = header.getOrDefault("X-Amz-Target")
  valid_595053 = validateParameter(valid_595053, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateByteMatchSet"))
  if valid_595053 != nil:
    section.add "X-Amz-Target", valid_595053
  var valid_595054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "X-Amz-Content-Sha256", valid_595054
  var valid_595055 = header.getOrDefault("X-Amz-Algorithm")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "X-Amz-Algorithm", valid_595055
  var valid_595056 = header.getOrDefault("X-Amz-Signature")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = nil)
  if valid_595056 != nil:
    section.add "X-Amz-Signature", valid_595056
  var valid_595057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "X-Amz-SignedHeaders", valid_595057
  var valid_595058 = header.getOrDefault("X-Amz-Credential")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "X-Amz-Credential", valid_595058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595060: Call_UpdateByteMatchSet_595048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>ByteMatchTuple</a> objects (filters) in a <a>ByteMatchSet</a>. For each <code>ByteMatchTuple</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>ByteMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspect, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The bytes (typically a string that corresponds with ASCII characters) that you want AWS WAF to look for. For more information, including how you specify the values for the AWS WAF API and the AWS CLI or SDKs, see <code>TargetString</code> in the <a>ByteMatchTuple</a> data type. </p> </li> <li> <p>Where to look, such as at the beginning or the end of a query string.</p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p>For example, you can add a <code>ByteMatchSetUpdate</code> object that matches web requests in which <code>User-Agent</code> headers contain the string <code>BadBot</code>. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>ByteMatchSet.</code> For more information, see <a>CreateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateByteMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595060.validator(path, query, header, formData, body)
  let scheme = call_595060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595060.url(scheme.get, call_595060.host, call_595060.base,
                         call_595060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595060, url, valid)

proc call*(call_595061: Call_UpdateByteMatchSet_595048; body: JsonNode): Recallable =
  ## updateByteMatchSet
  ## <p>Inserts or deletes <a>ByteMatchTuple</a> objects (filters) in a <a>ByteMatchSet</a>. For each <code>ByteMatchTuple</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>ByteMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspect, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The bytes (typically a string that corresponds with ASCII characters) that you want AWS WAF to look for. For more information, including how you specify the values for the AWS WAF API and the AWS CLI or SDKs, see <code>TargetString</code> in the <a>ByteMatchTuple</a> data type. </p> </li> <li> <p>Where to look, such as at the beginning or the end of a query string.</p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p>For example, you can add a <code>ByteMatchSetUpdate</code> object that matches web requests in which <code>User-Agent</code> headers contain the string <code>BadBot</code>. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>ByteMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>ByteMatchSet.</code> For more information, see <a>CreateByteMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateByteMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateByteMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595062 = newJObject()
  if body != nil:
    body_595062 = body
  result = call_595061.call(nil, nil, nil, nil, body_595062)

var updateByteMatchSet* = Call_UpdateByteMatchSet_595048(
    name: "updateByteMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateByteMatchSet",
    validator: validate_UpdateByteMatchSet_595049, base: "/",
    url: url_UpdateByteMatchSet_595050, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGeoMatchSet_595063 = ref object of OpenApiRestCall_593437
proc url_UpdateGeoMatchSet_595065(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateGeoMatchSet_595064(path: JsonNode; query: JsonNode;
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
  var valid_595066 = header.getOrDefault("X-Amz-Date")
  valid_595066 = validateParameter(valid_595066, JString, required = false,
                                 default = nil)
  if valid_595066 != nil:
    section.add "X-Amz-Date", valid_595066
  var valid_595067 = header.getOrDefault("X-Amz-Security-Token")
  valid_595067 = validateParameter(valid_595067, JString, required = false,
                                 default = nil)
  if valid_595067 != nil:
    section.add "X-Amz-Security-Token", valid_595067
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595068 = header.getOrDefault("X-Amz-Target")
  valid_595068 = validateParameter(valid_595068, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateGeoMatchSet"))
  if valid_595068 != nil:
    section.add "X-Amz-Target", valid_595068
  var valid_595069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595069 = validateParameter(valid_595069, JString, required = false,
                                 default = nil)
  if valid_595069 != nil:
    section.add "X-Amz-Content-Sha256", valid_595069
  var valid_595070 = header.getOrDefault("X-Amz-Algorithm")
  valid_595070 = validateParameter(valid_595070, JString, required = false,
                                 default = nil)
  if valid_595070 != nil:
    section.add "X-Amz-Algorithm", valid_595070
  var valid_595071 = header.getOrDefault("X-Amz-Signature")
  valid_595071 = validateParameter(valid_595071, JString, required = false,
                                 default = nil)
  if valid_595071 != nil:
    section.add "X-Amz-Signature", valid_595071
  var valid_595072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595072 = validateParameter(valid_595072, JString, required = false,
                                 default = nil)
  if valid_595072 != nil:
    section.add "X-Amz-SignedHeaders", valid_595072
  var valid_595073 = header.getOrDefault("X-Amz-Credential")
  valid_595073 = validateParameter(valid_595073, JString, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "X-Amz-Credential", valid_595073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595075: Call_UpdateGeoMatchSet_595063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>GeoMatchConstraint</a> objects in an <code>GeoMatchSet</code>. For each <code>GeoMatchConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>GeoMatchConstraint</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The <code>Type</code>. The only valid value for <code>Type</code> is <code>Country</code>.</p> </li> <li> <p>The <code>Value</code>, which is a two character code for the country to add to the <code>GeoMatchConstraint</code> object. Valid codes are listed in <a>GeoMatchConstraint$Value</a>.</p> </li> </ul> <p>To create and configure an <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateGeoMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSet</code> request to specify the country that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>GeoMatchSet</code>, you specify the country that you want to add and/or the country that you want to delete. If you want to change a country, you delete the existing country and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595075.validator(path, query, header, formData, body)
  let scheme = call_595075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595075.url(scheme.get, call_595075.host, call_595075.base,
                         call_595075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595075, url, valid)

proc call*(call_595076: Call_UpdateGeoMatchSet_595063; body: JsonNode): Recallable =
  ## updateGeoMatchSet
  ## <p>Inserts or deletes <a>GeoMatchConstraint</a> objects in an <code>GeoMatchSet</code>. For each <code>GeoMatchConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>GeoMatchConstraint</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The <code>Type</code>. The only valid value for <code>Type</code> is <code>Country</code>.</p> </li> <li> <p>The <code>Value</code>, which is a two character code for the country to add to the <code>GeoMatchConstraint</code> object. Valid codes are listed in <a>GeoMatchConstraint$Value</a>.</p> </li> </ul> <p>To create and configure an <code>GeoMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateGeoMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateGeoMatchSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateGeoMatchSet</code> request to specify the country that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>GeoMatchSet</code>, you specify the country that you want to add and/or the country that you want to delete. If you want to change a country, you delete the existing country and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595077 = newJObject()
  if body != nil:
    body_595077 = body
  result = call_595076.call(nil, nil, nil, nil, body_595077)

var updateGeoMatchSet* = Call_UpdateGeoMatchSet_595063(name: "updateGeoMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateGeoMatchSet",
    validator: validate_UpdateGeoMatchSet_595064, base: "/",
    url: url_UpdateGeoMatchSet_595065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIPSet_595078 = ref object of OpenApiRestCall_593437
proc url_UpdateIPSet_595080(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateIPSet_595079(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595081 = header.getOrDefault("X-Amz-Date")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Date", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Security-Token")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Security-Token", valid_595082
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595083 = header.getOrDefault("X-Amz-Target")
  valid_595083 = validateParameter(valid_595083, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateIPSet"))
  if valid_595083 != nil:
    section.add "X-Amz-Target", valid_595083
  var valid_595084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-Content-Sha256", valid_595084
  var valid_595085 = header.getOrDefault("X-Amz-Algorithm")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Algorithm", valid_595085
  var valid_595086 = header.getOrDefault("X-Amz-Signature")
  valid_595086 = validateParameter(valid_595086, JString, required = false,
                                 default = nil)
  if valid_595086 != nil:
    section.add "X-Amz-Signature", valid_595086
  var valid_595087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595087 = validateParameter(valid_595087, JString, required = false,
                                 default = nil)
  if valid_595087 != nil:
    section.add "X-Amz-SignedHeaders", valid_595087
  var valid_595088 = header.getOrDefault("X-Amz-Credential")
  valid_595088 = validateParameter(valid_595088, JString, required = false,
                                 default = nil)
  if valid_595088 != nil:
    section.add "X-Amz-Credential", valid_595088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595090: Call_UpdateIPSet_595078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>IPSetDescriptor</a> objects in an <code>IPSet</code>. For each <code>IPSetDescriptor</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>IPSetDescriptor</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The IP address version, <code>IPv4</code> or <code>IPv6</code>. </p> </li> <li> <p>The IP address in CIDR notation, for example, <code>192.0.2.0/24</code> (for the range of IP addresses from <code>192.0.2.0</code> to <code>192.0.2.255</code>) or <code>192.0.2.44/32</code> (for the individual IP address <code>192.0.2.44</code>). </p> </li> </ul> <p>AWS WAF supports IPv4 address ranges: /8 and any range between /16 through /32. AWS WAF supports IPv6 address ranges: /24, /32, /48, /56, /64, and /128. For more information about CIDR notation, see the Wikipedia entry <a href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">Classless Inter-Domain Routing</a>.</p> <p>IPv6 addresses can be represented using any of the following formats:</p> <ul> <li> <p>1111:0000:0000:0000:0000:0000:0000:0111/128</p> </li> <li> <p>1111:0:0:0:0:0:0:0111/128</p> </li> <li> <p>1111::0111/128</p> </li> <li> <p>1111::111/128</p> </li> </ul> <p>You use an <code>IPSet</code> to specify which web requests you want to allow or block based on the IP addresses that the requests originated from. For example, if you're receiving a lot of requests from one or a small number of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that specifies those IP addresses, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateIPSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>IPSet</code>, you specify the IP addresses that you want to add and/or the IP addresses that you want to delete. If you want to change an IP address, you delete the existing IP address and add the new one.</p> <p>You can insert a maximum of 1000 addresses in a single request.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595090.validator(path, query, header, formData, body)
  let scheme = call_595090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595090.url(scheme.get, call_595090.host, call_595090.base,
                         call_595090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595090, url, valid)

proc call*(call_595091: Call_UpdateIPSet_595078; body: JsonNode): Recallable =
  ## updateIPSet
  ## <p>Inserts or deletes <a>IPSetDescriptor</a> objects in an <code>IPSet</code>. For each <code>IPSetDescriptor</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change an <code>IPSetDescriptor</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The IP address version, <code>IPv4</code> or <code>IPv6</code>. </p> </li> <li> <p>The IP address in CIDR notation, for example, <code>192.0.2.0/24</code> (for the range of IP addresses from <code>192.0.2.0</code> to <code>192.0.2.255</code>) or <code>192.0.2.44/32</code> (for the individual IP address <code>192.0.2.44</code>). </p> </li> </ul> <p>AWS WAF supports IPv4 address ranges: /8 and any range between /16 through /32. AWS WAF supports IPv6 address ranges: /24, /32, /48, /56, /64, and /128. For more information about CIDR notation, see the Wikipedia entry <a href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">Classless Inter-Domain Routing</a>.</p> <p>IPv6 addresses can be represented using any of the following formats:</p> <ul> <li> <p>1111:0000:0000:0000:0000:0000:0000:0111/128</p> </li> <li> <p>1111:0:0:0:0:0:0:0111/128</p> </li> <li> <p>1111::0111/128</p> </li> <li> <p>1111::111/128</p> </li> </ul> <p>You use an <code>IPSet</code> to specify which web requests you want to allow or block based on the IP addresses that the requests originated from. For example, if you're receiving a lot of requests from one or a small number of IP addresses and you want to block the requests, you can create an <code>IPSet</code> that specifies those IP addresses, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>IPSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateIPSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateIPSet</code> request to specify the IP addresses that you want AWS WAF to watch for.</p> </li> </ol> <p>When you update an <code>IPSet</code>, you specify the IP addresses that you want to add and/or the IP addresses that you want to delete. If you want to change an IP address, you delete the existing IP address and add the new one.</p> <p>You can insert a maximum of 1000 addresses in a single request.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595092 = newJObject()
  if body != nil:
    body_595092 = body
  result = call_595091.call(nil, nil, nil, nil, body_595092)

var updateIPSet* = Call_UpdateIPSet_595078(name: "updateIPSet",
                                        meth: HttpMethod.HttpPost,
                                        host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateIPSet",
                                        validator: validate_UpdateIPSet_595079,
                                        base: "/", url: url_UpdateIPSet_595080,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRateBasedRule_595093 = ref object of OpenApiRestCall_593437
proc url_UpdateRateBasedRule_595095(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRateBasedRule_595094(path: JsonNode; query: JsonNode;
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
  var valid_595096 = header.getOrDefault("X-Amz-Date")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Date", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-Security-Token")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-Security-Token", valid_595097
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595098 = header.getOrDefault("X-Amz-Target")
  valid_595098 = validateParameter(valid_595098, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRateBasedRule"))
  if valid_595098 != nil:
    section.add "X-Amz-Target", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-Content-Sha256", valid_595099
  var valid_595100 = header.getOrDefault("X-Amz-Algorithm")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Algorithm", valid_595100
  var valid_595101 = header.getOrDefault("X-Amz-Signature")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "X-Amz-Signature", valid_595101
  var valid_595102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "X-Amz-SignedHeaders", valid_595102
  var valid_595103 = header.getOrDefault("X-Amz-Credential")
  valid_595103 = validateParameter(valid_595103, JString, required = false,
                                 default = nil)
  if valid_595103 != nil:
    section.add "X-Amz-Credential", valid_595103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595105: Call_UpdateRateBasedRule_595093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>Predicate</a> objects in a rule and updates the <code>RateLimit</code> in the rule. </p> <p>Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to block or count. The <code>RateLimit</code> specifies the number of requests every five minutes that triggers the rule.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request must match all the predicates and exceed the <code>RateLimit</code> to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions much be received at a rate of more than 15,000 every five minutes. If the rate drops below this limit, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p>
  ## 
  let valid = call_595105.validator(path, query, header, formData, body)
  let scheme = call_595105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595105.url(scheme.get, call_595105.host, call_595105.base,
                         call_595105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595105, url, valid)

proc call*(call_595106: Call_UpdateRateBasedRule_595093; body: JsonNode): Recallable =
  ## updateRateBasedRule
  ## <p>Inserts or deletes <a>Predicate</a> objects in a rule and updates the <code>RateLimit</code> in the rule. </p> <p>Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to block or count. The <code>RateLimit</code> specifies the number of requests every five minutes that triggers the rule.</p> <p>If you add more than one predicate to a <code>RateBasedRule</code>, a request must match all the predicates and exceed the <code>RateLimit</code> to be counted or blocked. For example, suppose you add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44/32</code> </p> </li> <li> <p>A <code>ByteMatchSet</code> that matches <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>You then add the <code>RateBasedRule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 <i>and</i> the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code>. Further, requests that match these two conditions much be received at a rate of more than 15,000 every five minutes. If the rate drops below this limit, AWS WAF no longer blocks the requests.</p> <p>As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a <code>RateBasedRule</code>:</p> <ul> <li> <p>A <code>ByteMatchSet</code> with <code>FieldToMatch</code> of <code>URI</code> </p> </li> <li> <p>A <code>PositionalConstraint</code> of <code>STARTS_WITH</code> </p> </li> <li> <p>A <code>TargetString</code> of <code>login</code> </p> </li> </ul> <p>Further, you specify a <code>RateLimit</code> of 15,000.</p> <p>By adding this <code>RateBasedRule</code> to a <code>WebACL</code>, you could limit requests to your login page without affecting the rest of your site.</p>
  ##   body: JObject (required)
  var body_595107 = newJObject()
  if body != nil:
    body_595107 = body
  result = call_595106.call(nil, nil, nil, nil, body_595107)

var updateRateBasedRule* = Call_UpdateRateBasedRule_595093(
    name: "updateRateBasedRule", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRateBasedRule",
    validator: validate_UpdateRateBasedRule_595094, base: "/",
    url: url_UpdateRateBasedRule_595095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegexMatchSet_595108 = ref object of OpenApiRestCall_593437
proc url_UpdateRegexMatchSet_595110(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRegexMatchSet_595109(path: JsonNode; query: JsonNode;
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
  var valid_595111 = header.getOrDefault("X-Amz-Date")
  valid_595111 = validateParameter(valid_595111, JString, required = false,
                                 default = nil)
  if valid_595111 != nil:
    section.add "X-Amz-Date", valid_595111
  var valid_595112 = header.getOrDefault("X-Amz-Security-Token")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "X-Amz-Security-Token", valid_595112
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595113 = header.getOrDefault("X-Amz-Target")
  valid_595113 = validateParameter(valid_595113, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRegexMatchSet"))
  if valid_595113 != nil:
    section.add "X-Amz-Target", valid_595113
  var valid_595114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595114 = validateParameter(valid_595114, JString, required = false,
                                 default = nil)
  if valid_595114 != nil:
    section.add "X-Amz-Content-Sha256", valid_595114
  var valid_595115 = header.getOrDefault("X-Amz-Algorithm")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Algorithm", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-Signature")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-Signature", valid_595116
  var valid_595117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-SignedHeaders", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-Credential")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-Credential", valid_595118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595120: Call_UpdateRegexMatchSet_595108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>RegexMatchTuple</a> objects (filters) in a <a>RegexMatchSet</a>. For each <code>RegexMatchSetUpdate</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>RegexMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspectupdate, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The identifier of the pattern (a regular expression) that you want AWS WAF to look for. For more information, see <a>RegexPatternSet</a>. </p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p> For example, you can create a <code>RegexPatternSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexMatchSet.</code> For more information, see <a>CreateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the identifier of the <code>RegexPatternSet</code> that contain the regular expression patters you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595120.validator(path, query, header, formData, body)
  let scheme = call_595120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595120.url(scheme.get, call_595120.host, call_595120.base,
                         call_595120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595120, url, valid)

proc call*(call_595121: Call_UpdateRegexMatchSet_595108; body: JsonNode): Recallable =
  ## updateRegexMatchSet
  ## <p>Inserts or deletes <a>RegexMatchTuple</a> objects (filters) in a <a>RegexMatchSet</a>. For each <code>RegexMatchSetUpdate</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>RegexMatchSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to inspectupdate, such as a query string or the value of the <code>User-Agent</code> header. </p> </li> <li> <p>The identifier of the pattern (a regular expression) that you want AWS WAF to look for. For more information, see <a>RegexPatternSet</a>. </p> </li> <li> <p>Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string.</p> </li> </ul> <p> For example, you can create a <code>RegexPatternSet</code> that matches any requests with <code>User-Agent</code> headers that contain the string <code>B[a@]dB[o0]t</code>. You can then configure AWS WAF to reject those requests.</p> <p>To create and configure a <code>RegexMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexMatchSet.</code> For more information, see <a>CreateRegexMatchSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexMatchSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexMatchSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the identifier of the <code>RegexPatternSet</code> that contain the regular expression patters you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595122 = newJObject()
  if body != nil:
    body_595122 = body
  result = call_595121.call(nil, nil, nil, nil, body_595122)

var updateRegexMatchSet* = Call_UpdateRegexMatchSet_595108(
    name: "updateRegexMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRegexMatchSet",
    validator: validate_UpdateRegexMatchSet_595109, base: "/",
    url: url_UpdateRegexMatchSet_595110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRegexPatternSet_595123 = ref object of OpenApiRestCall_593437
proc url_UpdateRegexPatternSet_595125(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRegexPatternSet_595124(path: JsonNode; query: JsonNode;
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
  var valid_595126 = header.getOrDefault("X-Amz-Date")
  valid_595126 = validateParameter(valid_595126, JString, required = false,
                                 default = nil)
  if valid_595126 != nil:
    section.add "X-Amz-Date", valid_595126
  var valid_595127 = header.getOrDefault("X-Amz-Security-Token")
  valid_595127 = validateParameter(valid_595127, JString, required = false,
                                 default = nil)
  if valid_595127 != nil:
    section.add "X-Amz-Security-Token", valid_595127
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595128 = header.getOrDefault("X-Amz-Target")
  valid_595128 = validateParameter(valid_595128, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRegexPatternSet"))
  if valid_595128 != nil:
    section.add "X-Amz-Target", valid_595128
  var valid_595129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595129 = validateParameter(valid_595129, JString, required = false,
                                 default = nil)
  if valid_595129 != nil:
    section.add "X-Amz-Content-Sha256", valid_595129
  var valid_595130 = header.getOrDefault("X-Amz-Algorithm")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Algorithm", valid_595130
  var valid_595131 = header.getOrDefault("X-Amz-Signature")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "X-Amz-Signature", valid_595131
  var valid_595132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-SignedHeaders", valid_595132
  var valid_595133 = header.getOrDefault("X-Amz-Credential")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Credential", valid_595133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595135: Call_UpdateRegexPatternSet_595123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <code>RegexPatternString</code> objects in a <a>RegexPatternSet</a>. For each <code>RegexPatternString</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the <code>RegexPatternString</code>.</p> </li> <li> <p>The regular expression pattern that you want to insert or delete. For more information, see <a>RegexPatternSet</a>. </p> </li> </ul> <p> For example, you can create a <code>RegexPatternString</code> such as <code>B[a@]dB[o0]t</code>. AWS WAF will match this <code>RegexPatternString</code> to:</p> <ul> <li> <p>BadBot</p> </li> <li> <p>BadB0t</p> </li> <li> <p>B@dBot</p> </li> <li> <p>B@dB0t</p> </li> </ul> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexPatternSet.</code> For more information, see <a>CreateRegexPatternSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexPatternSet</code> request to specify the regular expression pattern that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595135.validator(path, query, header, formData, body)
  let scheme = call_595135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595135.url(scheme.get, call_595135.host, call_595135.base,
                         call_595135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595135, url, valid)

proc call*(call_595136: Call_UpdateRegexPatternSet_595123; body: JsonNode): Recallable =
  ## updateRegexPatternSet
  ## <p>Inserts or deletes <code>RegexPatternString</code> objects in a <a>RegexPatternSet</a>. For each <code>RegexPatternString</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the <code>RegexPatternString</code>.</p> </li> <li> <p>The regular expression pattern that you want to insert or delete. For more information, see <a>RegexPatternSet</a>. </p> </li> </ul> <p> For example, you can create a <code>RegexPatternString</code> such as <code>B[a@]dB[o0]t</code>. AWS WAF will match this <code>RegexPatternString</code> to:</p> <ul> <li> <p>BadBot</p> </li> <li> <p>BadB0t</p> </li> <li> <p>B@dBot</p> </li> <li> <p>B@dB0t</p> </li> </ul> <p>To create and configure a <code>RegexPatternSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>RegexPatternSet.</code> For more information, see <a>CreateRegexPatternSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateRegexPatternSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateRegexPatternSet</code> request to specify the regular expression pattern that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595137 = newJObject()
  if body != nil:
    body_595137 = body
  result = call_595136.call(nil, nil, nil, nil, body_595137)

var updateRegexPatternSet* = Call_UpdateRegexPatternSet_595123(
    name: "updateRegexPatternSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRegexPatternSet",
    validator: validate_UpdateRegexPatternSet_595124, base: "/",
    url: url_UpdateRegexPatternSet_595125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRule_595138 = ref object of OpenApiRestCall_593437
proc url_UpdateRule_595140(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRule_595139(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595141 = header.getOrDefault("X-Amz-Date")
  valid_595141 = validateParameter(valid_595141, JString, required = false,
                                 default = nil)
  if valid_595141 != nil:
    section.add "X-Amz-Date", valid_595141
  var valid_595142 = header.getOrDefault("X-Amz-Security-Token")
  valid_595142 = validateParameter(valid_595142, JString, required = false,
                                 default = nil)
  if valid_595142 != nil:
    section.add "X-Amz-Security-Token", valid_595142
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595143 = header.getOrDefault("X-Amz-Target")
  valid_595143 = validateParameter(valid_595143, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRule"))
  if valid_595143 != nil:
    section.add "X-Amz-Target", valid_595143
  var valid_595144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595144 = validateParameter(valid_595144, JString, required = false,
                                 default = nil)
  if valid_595144 != nil:
    section.add "X-Amz-Content-Sha256", valid_595144
  var valid_595145 = header.getOrDefault("X-Amz-Algorithm")
  valid_595145 = validateParameter(valid_595145, JString, required = false,
                                 default = nil)
  if valid_595145 != nil:
    section.add "X-Amz-Algorithm", valid_595145
  var valid_595146 = header.getOrDefault("X-Amz-Signature")
  valid_595146 = validateParameter(valid_595146, JString, required = false,
                                 default = nil)
  if valid_595146 != nil:
    section.add "X-Amz-Signature", valid_595146
  var valid_595147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-SignedHeaders", valid_595147
  var valid_595148 = header.getOrDefault("X-Amz-Credential")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Credential", valid_595148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595150: Call_UpdateRule_595138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>Predicate</a> objects in a <code>Rule</code>. Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to allow, block, or count. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed, blocked, or counted. For example, suppose that you add the following to a <code>Rule</code>: </p> <ul> <li> <p>A <code>ByteMatchSet</code> that matches the value <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44</code> </p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the <code>Rule</code>. For a request to be blocked, the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code> <i>and</i> the request must originate from the IP address 192.0.2.44.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create the <code>Rule</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to add predicates to the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>ByteMatchSet</code> or <code>IPSet</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595150.validator(path, query, header, formData, body)
  let scheme = call_595150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595150.url(scheme.get, call_595150.host, call_595150.base,
                         call_595150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595150, url, valid)

proc call*(call_595151: Call_UpdateRule_595138; body: JsonNode): Recallable =
  ## updateRule
  ## <p>Inserts or deletes <a>Predicate</a> objects in a <code>Rule</code>. Each <code>Predicate</code> object identifies a predicate, such as a <a>ByteMatchSet</a> or an <a>IPSet</a>, that specifies the web requests that you want to allow, block, or count. If you add more than one predicate to a <code>Rule</code>, a request must match all of the specifications to be allowed, blocked, or counted. For example, suppose that you add the following to a <code>Rule</code>: </p> <ul> <li> <p>A <code>ByteMatchSet</code> that matches the value <code>BadBot</code> in the <code>User-Agent</code> header</p> </li> <li> <p>An <code>IPSet</code> that matches the IP address <code>192.0.2.44</code> </p> </li> </ul> <p>You then add the <code>Rule</code> to a <code>WebACL</code> and specify that you want to block requests that satisfy the <code>Rule</code>. For a request to be blocked, the <code>User-Agent</code> header in the request must contain the value <code>BadBot</code> <i>and</i> the request must originate from the IP address 192.0.2.44.</p> <p>To create and configure a <code>Rule</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in the <code>Rule</code>.</p> </li> <li> <p>Create the <code>Rule</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRule</a> request.</p> </li> <li> <p>Submit an <code>UpdateRule</code> request to add predicates to the <code>Rule</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>Rule</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>ByteMatchSet</code> or <code>IPSet</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595152 = newJObject()
  if body != nil:
    body_595152 = body
  result = call_595151.call(nil, nil, nil, nil, body_595152)

var updateRule* = Call_UpdateRule_595138(name: "updateRule",
                                      meth: HttpMethod.HttpPost,
                                      host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRule",
                                      validator: validate_UpdateRule_595139,
                                      base: "/", url: url_UpdateRule_595140,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRuleGroup_595153 = ref object of OpenApiRestCall_593437
proc url_UpdateRuleGroup_595155(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRuleGroup_595154(path: JsonNode; query: JsonNode;
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
  var valid_595156 = header.getOrDefault("X-Amz-Date")
  valid_595156 = validateParameter(valid_595156, JString, required = false,
                                 default = nil)
  if valid_595156 != nil:
    section.add "X-Amz-Date", valid_595156
  var valid_595157 = header.getOrDefault("X-Amz-Security-Token")
  valid_595157 = validateParameter(valid_595157, JString, required = false,
                                 default = nil)
  if valid_595157 != nil:
    section.add "X-Amz-Security-Token", valid_595157
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595158 = header.getOrDefault("X-Amz-Target")
  valid_595158 = validateParameter(valid_595158, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateRuleGroup"))
  if valid_595158 != nil:
    section.add "X-Amz-Target", valid_595158
  var valid_595159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595159 = validateParameter(valid_595159, JString, required = false,
                                 default = nil)
  if valid_595159 != nil:
    section.add "X-Amz-Content-Sha256", valid_595159
  var valid_595160 = header.getOrDefault("X-Amz-Algorithm")
  valid_595160 = validateParameter(valid_595160, JString, required = false,
                                 default = nil)
  if valid_595160 != nil:
    section.add "X-Amz-Algorithm", valid_595160
  var valid_595161 = header.getOrDefault("X-Amz-Signature")
  valid_595161 = validateParameter(valid_595161, JString, required = false,
                                 default = nil)
  if valid_595161 != nil:
    section.add "X-Amz-Signature", valid_595161
  var valid_595162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-SignedHeaders", valid_595162
  var valid_595163 = header.getOrDefault("X-Amz-Credential")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Credential", valid_595163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595165: Call_UpdateRuleGroup_595153; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>RuleGroup</code>.</p> <p>You can only insert <code>REGULAR</code> rules into a rule group.</p> <p>You can have a maximum of ten rules per rule group.</p> <p>To create and configure a <code>RuleGroup</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>RuleGroup</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRuleGroup</a> request.</p> </li> <li> <p>Submit an <code>UpdateRuleGroup</code> request to add <code>Rules</code> to the <code>RuleGroup</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RuleGroup</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>Rule</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595165.validator(path, query, header, formData, body)
  let scheme = call_595165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595165.url(scheme.get, call_595165.host, call_595165.base,
                         call_595165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595165, url, valid)

proc call*(call_595166: Call_UpdateRuleGroup_595153; body: JsonNode): Recallable =
  ## updateRuleGroup
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>RuleGroup</code>.</p> <p>You can only insert <code>REGULAR</code> rules into a rule group.</p> <p>You can have a maximum of ten rules per rule group.</p> <p>To create and configure a <code>RuleGroup</code>, perform the following steps:</p> <ol> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>RuleGroup</code>. See <a>CreateRule</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateRuleGroup</a> request.</p> </li> <li> <p>Submit an <code>UpdateRuleGroup</code> request to add <code>Rules</code> to the <code>RuleGroup</code>.</p> </li> <li> <p>Create and update a <code>WebACL</code> that contains the <code>RuleGroup</code>. See <a>CreateWebACL</a>.</p> </li> </ol> <p>If you want to replace one <code>Rule</code> with another, you delete the existing one and add the new one.</p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595167 = newJObject()
  if body != nil:
    body_595167 = body
  result = call_595166.call(nil, nil, nil, nil, body_595167)

var updateRuleGroup* = Call_UpdateRuleGroup_595153(name: "updateRuleGroup",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateRuleGroup",
    validator: validate_UpdateRuleGroup_595154, base: "/", url: url_UpdateRuleGroup_595155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSizeConstraintSet_595168 = ref object of OpenApiRestCall_593437
proc url_UpdateSizeConstraintSet_595170(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSizeConstraintSet_595169(path: JsonNode; query: JsonNode;
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
  var valid_595171 = header.getOrDefault("X-Amz-Date")
  valid_595171 = validateParameter(valid_595171, JString, required = false,
                                 default = nil)
  if valid_595171 != nil:
    section.add "X-Amz-Date", valid_595171
  var valid_595172 = header.getOrDefault("X-Amz-Security-Token")
  valid_595172 = validateParameter(valid_595172, JString, required = false,
                                 default = nil)
  if valid_595172 != nil:
    section.add "X-Amz-Security-Token", valid_595172
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595173 = header.getOrDefault("X-Amz-Target")
  valid_595173 = validateParameter(valid_595173, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateSizeConstraintSet"))
  if valid_595173 != nil:
    section.add "X-Amz-Target", valid_595173
  var valid_595174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595174 = validateParameter(valid_595174, JString, required = false,
                                 default = nil)
  if valid_595174 != nil:
    section.add "X-Amz-Content-Sha256", valid_595174
  var valid_595175 = header.getOrDefault("X-Amz-Algorithm")
  valid_595175 = validateParameter(valid_595175, JString, required = false,
                                 default = nil)
  if valid_595175 != nil:
    section.add "X-Amz-Algorithm", valid_595175
  var valid_595176 = header.getOrDefault("X-Amz-Signature")
  valid_595176 = validateParameter(valid_595176, JString, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "X-Amz-Signature", valid_595176
  var valid_595177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595177 = validateParameter(valid_595177, JString, required = false,
                                 default = nil)
  if valid_595177 != nil:
    section.add "X-Amz-SignedHeaders", valid_595177
  var valid_595178 = header.getOrDefault("X-Amz-Credential")
  valid_595178 = validateParameter(valid_595178, JString, required = false,
                                 default = nil)
  if valid_595178 != nil:
    section.add "X-Amz-Credential", valid_595178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595180: Call_UpdateSizeConstraintSet_595168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>SizeConstraint</a> objects (filters) in a <a>SizeConstraintSet</a>. For each <code>SizeConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>SizeConstraintSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to evaluate, such as the length of a query string or the length of the <code>User-Agent</code> header.</p> </li> <li> <p>Whether to perform any transformations on the request, such as converting it to lowercase, before checking its length. Note that transformations of the request body are not supported because the AWS resource forwards only the first <code>8192</code> bytes of your request to AWS WAF.</p> <p>You can only specify a single type of TextTransformation.</p> </li> <li> <p>A <code>ComparisonOperator</code> used for evaluating the selected part of the request against the specified <code>Size</code>, such as equals, greater than, less than, and so on.</p> </li> <li> <p>The length, in bytes, that you want AWS WAF to watch for in selected part of the request. The length is computed after applying the transformation.</p> </li> </ul> <p>For example, you can add a <code>SizeConstraintSetUpdate</code> object that matches web requests in which the length of the <code>User-Agent</code> header is greater than 100 bytes. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>SizeConstraintSet.</code> For more information, see <a>CreateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateSizeConstraintSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595180.validator(path, query, header, formData, body)
  let scheme = call_595180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595180.url(scheme.get, call_595180.host, call_595180.base,
                         call_595180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595180, url, valid)

proc call*(call_595181: Call_UpdateSizeConstraintSet_595168; body: JsonNode): Recallable =
  ## updateSizeConstraintSet
  ## <p>Inserts or deletes <a>SizeConstraint</a> objects (filters) in a <a>SizeConstraintSet</a>. For each <code>SizeConstraint</code> object, you specify the following values: </p> <ul> <li> <p>Whether to insert or delete the object from the array. If you want to change a <code>SizeConstraintSetUpdate</code> object, you delete the existing object and add a new one.</p> </li> <li> <p>The part of a web request that you want AWS WAF to evaluate, such as the length of a query string or the length of the <code>User-Agent</code> header.</p> </li> <li> <p>Whether to perform any transformations on the request, such as converting it to lowercase, before checking its length. Note that transformations of the request body are not supported because the AWS resource forwards only the first <code>8192</code> bytes of your request to AWS WAF.</p> <p>You can only specify a single type of TextTransformation.</p> </li> <li> <p>A <code>ComparisonOperator</code> used for evaluating the selected part of the request against the specified <code>Size</code>, such as equals, greater than, less than, and so on.</p> </li> <li> <p>The length, in bytes, that you want AWS WAF to watch for in selected part of the request. The length is computed after applying the transformation.</p> </li> </ul> <p>For example, you can add a <code>SizeConstraintSetUpdate</code> object that matches web requests in which the length of the <code>User-Agent</code> header is greater than 100 bytes. You can then configure AWS WAF to block those requests.</p> <p>To create and configure a <code>SizeConstraintSet</code>, perform the following steps:</p> <ol> <li> <p>Create a <code>SizeConstraintSet.</code> For more information, see <a>CreateSizeConstraintSet</a>.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <code>UpdateSizeConstraintSet</code> request.</p> </li> <li> <p>Submit an <code>UpdateSizeConstraintSet</code> request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595182 = newJObject()
  if body != nil:
    body_595182 = body
  result = call_595181.call(nil, nil, nil, nil, body_595182)

var updateSizeConstraintSet* = Call_UpdateSizeConstraintSet_595168(
    name: "updateSizeConstraintSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateSizeConstraintSet",
    validator: validate_UpdateSizeConstraintSet_595169, base: "/",
    url: url_UpdateSizeConstraintSet_595170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSqlInjectionMatchSet_595183 = ref object of OpenApiRestCall_593437
proc url_UpdateSqlInjectionMatchSet_595185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSqlInjectionMatchSet_595184(path: JsonNode; query: JsonNode;
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
  var valid_595186 = header.getOrDefault("X-Amz-Date")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Date", valid_595186
  var valid_595187 = header.getOrDefault("X-Amz-Security-Token")
  valid_595187 = validateParameter(valid_595187, JString, required = false,
                                 default = nil)
  if valid_595187 != nil:
    section.add "X-Amz-Security-Token", valid_595187
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595188 = header.getOrDefault("X-Amz-Target")
  valid_595188 = validateParameter(valid_595188, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateSqlInjectionMatchSet"))
  if valid_595188 != nil:
    section.add "X-Amz-Target", valid_595188
  var valid_595189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595189 = validateParameter(valid_595189, JString, required = false,
                                 default = nil)
  if valid_595189 != nil:
    section.add "X-Amz-Content-Sha256", valid_595189
  var valid_595190 = header.getOrDefault("X-Amz-Algorithm")
  valid_595190 = validateParameter(valid_595190, JString, required = false,
                                 default = nil)
  if valid_595190 != nil:
    section.add "X-Amz-Algorithm", valid_595190
  var valid_595191 = header.getOrDefault("X-Amz-Signature")
  valid_595191 = validateParameter(valid_595191, JString, required = false,
                                 default = nil)
  if valid_595191 != nil:
    section.add "X-Amz-Signature", valid_595191
  var valid_595192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595192 = validateParameter(valid_595192, JString, required = false,
                                 default = nil)
  if valid_595192 != nil:
    section.add "X-Amz-SignedHeaders", valid_595192
  var valid_595193 = header.getOrDefault("X-Amz-Credential")
  valid_595193 = validateParameter(valid_595193, JString, required = false,
                                 default = nil)
  if valid_595193 != nil:
    section.add "X-Amz-Credential", valid_595193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595195: Call_UpdateSqlInjectionMatchSet_595183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>SqlInjectionMatchTuple</a> objects (filters) in a <a>SqlInjectionMatchSet</a>. For each <code>SqlInjectionMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change a <code>SqlInjectionMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for snippets of malicious SQL code.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>SqlInjectionMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain snippets of SQL code in the query string and you want to block the requests, you can create a <code>SqlInjectionMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateSqlInjectionMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for snippets of SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595195.validator(path, query, header, formData, body)
  let scheme = call_595195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595195.url(scheme.get, call_595195.host, call_595195.base,
                         call_595195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595195, url, valid)

proc call*(call_595196: Call_UpdateSqlInjectionMatchSet_595183; body: JsonNode): Recallable =
  ## updateSqlInjectionMatchSet
  ## <p>Inserts or deletes <a>SqlInjectionMatchTuple</a> objects (filters) in a <a>SqlInjectionMatchSet</a>. For each <code>SqlInjectionMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change a <code>SqlInjectionMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for snippets of malicious SQL code.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>SqlInjectionMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain snippets of SQL code in the query string and you want to block the requests, you can create a <code>SqlInjectionMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure a <code>SqlInjectionMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateSqlInjectionMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateSqlInjectionMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for snippets of SQL code.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595197 = newJObject()
  if body != nil:
    body_595197 = body
  result = call_595196.call(nil, nil, nil, nil, body_595197)

var updateSqlInjectionMatchSet* = Call_UpdateSqlInjectionMatchSet_595183(
    name: "updateSqlInjectionMatchSet", meth: HttpMethod.HttpPost,
    host: "waf-regional.amazonaws.com", route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateSqlInjectionMatchSet",
    validator: validate_UpdateSqlInjectionMatchSet_595184, base: "/",
    url: url_UpdateSqlInjectionMatchSet_595185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateWebACL_595198 = ref object of OpenApiRestCall_593437
proc url_UpdateWebACL_595200(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateWebACL_595199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_595201 = header.getOrDefault("X-Amz-Date")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Date", valid_595201
  var valid_595202 = header.getOrDefault("X-Amz-Security-Token")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "X-Amz-Security-Token", valid_595202
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595203 = header.getOrDefault("X-Amz-Target")
  valid_595203 = validateParameter(valid_595203, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateWebACL"))
  if valid_595203 != nil:
    section.add "X-Amz-Target", valid_595203
  var valid_595204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595204 = validateParameter(valid_595204, JString, required = false,
                                 default = nil)
  if valid_595204 != nil:
    section.add "X-Amz-Content-Sha256", valid_595204
  var valid_595205 = header.getOrDefault("X-Amz-Algorithm")
  valid_595205 = validateParameter(valid_595205, JString, required = false,
                                 default = nil)
  if valid_595205 != nil:
    section.add "X-Amz-Algorithm", valid_595205
  var valid_595206 = header.getOrDefault("X-Amz-Signature")
  valid_595206 = validateParameter(valid_595206, JString, required = false,
                                 default = nil)
  if valid_595206 != nil:
    section.add "X-Amz-Signature", valid_595206
  var valid_595207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595207 = validateParameter(valid_595207, JString, required = false,
                                 default = nil)
  if valid_595207 != nil:
    section.add "X-Amz-SignedHeaders", valid_595207
  var valid_595208 = header.getOrDefault("X-Amz-Credential")
  valid_595208 = validateParameter(valid_595208, JString, required = false,
                                 default = nil)
  if valid_595208 != nil:
    section.add "X-Amz-Credential", valid_595208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595210: Call_UpdateWebACL_595198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>WebACL</code>. Each <code>Rule</code> identifies web requests that you want to allow, block, or count. When you update a <code>WebACL</code>, you specify the following values:</p> <ul> <li> <p>A default action for the <code>WebACL</code>, either <code>ALLOW</code> or <code>BLOCK</code>. AWS WAF performs the default action if a request doesn't match the criteria in any of the <code>Rules</code> in a <code>WebACL</code>.</p> </li> <li> <p>The <code>Rules</code> that you want to add or delete. If you want to replace one <code>Rule</code> with another, you delete the existing <code>Rule</code> and add the new one.</p> </li> <li> <p>For each <code>Rule</code>, whether you want AWS WAF to allow requests, block requests, or count requests that match the conditions in the <code>Rule</code>.</p> </li> <li> <p>The order in which you want AWS WAF to evaluate the <code>Rules</code> in a <code>WebACL</code>. If you add more than one <code>Rule</code> to a <code>WebACL</code>, AWS WAF evaluates each request against the <code>Rules</code> in order based on the value of <code>Priority</code>. (The <code>Rule</code> that has the lowest value for <code>Priority</code> is evaluated first.) When a web request matches all the predicates (such as <code>ByteMatchSets</code> and <code>IPSets</code>) in a <code>Rule</code>, AWS WAF immediately takes the corresponding action, allow or block, and doesn't evaluate the request against the remaining <code>Rules</code> in the <code>WebACL</code>, if any. </p> </li> </ul> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Create a <code>WebACL</code>. See <a>CreateWebACL</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <code>UpdateWebACL</code> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution. </p> <p>The <code>ActivatedRule</code> can be a rule group. If you specify a rule group as your <code>ActivatedRule</code>, you can exclude specific rules from that rule group.</p> <p>If you already have a rule group associated with a web ACL and want to submit an <code>UpdateWebACL</code> request to exclude certain rules from that rule group, you must first remove the rule group from the web ACL, the re-insert it again, specifying the excluded rules. For details, see <a>ActivatedRule$ExcludedRules</a>. </p> </li> </ol> <p>Be aware that if you try to add a RATE_BASED rule to a web ACL without setting the rule type when first creating the rule, the <a>UpdateWebACL</a> request will fail because the request tries to add a REGULAR rule (the default rule type) with the specified ID, which does not exist. </p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595210.validator(path, query, header, formData, body)
  let scheme = call_595210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595210.url(scheme.get, call_595210.host, call_595210.base,
                         call_595210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595210, url, valid)

proc call*(call_595211: Call_UpdateWebACL_595198; body: JsonNode): Recallable =
  ## updateWebACL
  ## <p>Inserts or deletes <a>ActivatedRule</a> objects in a <code>WebACL</code>. Each <code>Rule</code> identifies web requests that you want to allow, block, or count. When you update a <code>WebACL</code>, you specify the following values:</p> <ul> <li> <p>A default action for the <code>WebACL</code>, either <code>ALLOW</code> or <code>BLOCK</code>. AWS WAF performs the default action if a request doesn't match the criteria in any of the <code>Rules</code> in a <code>WebACL</code>.</p> </li> <li> <p>The <code>Rules</code> that you want to add or delete. If you want to replace one <code>Rule</code> with another, you delete the existing <code>Rule</code> and add the new one.</p> </li> <li> <p>For each <code>Rule</code>, whether you want AWS WAF to allow requests, block requests, or count requests that match the conditions in the <code>Rule</code>.</p> </li> <li> <p>The order in which you want AWS WAF to evaluate the <code>Rules</code> in a <code>WebACL</code>. If you add more than one <code>Rule</code> to a <code>WebACL</code>, AWS WAF evaluates each request against the <code>Rules</code> in order based on the value of <code>Priority</code>. (The <code>Rule</code> that has the lowest value for <code>Priority</code> is evaluated first.) When a web request matches all the predicates (such as <code>ByteMatchSets</code> and <code>IPSets</code>) in a <code>Rule</code>, AWS WAF immediately takes the corresponding action, allow or block, and doesn't evaluate the request against the remaining <code>Rules</code> in the <code>WebACL</code>, if any. </p> </li> </ul> <p>To create and configure a <code>WebACL</code>, perform the following steps:</p> <ol> <li> <p>Create and update the predicates that you want to include in <code>Rules</code>. For more information, see <a>CreateByteMatchSet</a>, <a>UpdateByteMatchSet</a>, <a>CreateIPSet</a>, <a>UpdateIPSet</a>, <a>CreateSqlInjectionMatchSet</a>, and <a>UpdateSqlInjectionMatchSet</a>.</p> </li> <li> <p>Create and update the <code>Rules</code> that you want to include in the <code>WebACL</code>. For more information, see <a>CreateRule</a> and <a>UpdateRule</a>.</p> </li> <li> <p>Create a <code>WebACL</code>. See <a>CreateWebACL</a>.</p> </li> <li> <p>Use <code>GetChangeToken</code> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateWebACL</a> request.</p> </li> <li> <p>Submit an <code>UpdateWebACL</code> request to specify the <code>Rules</code> that you want to include in the <code>WebACL</code>, to specify the default action, and to associate the <code>WebACL</code> with a CloudFront distribution. </p> <p>The <code>ActivatedRule</code> can be a rule group. If you specify a rule group as your <code>ActivatedRule</code>, you can exclude specific rules from that rule group.</p> <p>If you already have a rule group associated with a web ACL and want to submit an <code>UpdateWebACL</code> request to exclude certain rules from that rule group, you must first remove the rule group from the web ACL, the re-insert it again, specifying the excluded rules. For details, see <a>ActivatedRule$ExcludedRules</a>. </p> </li> </ol> <p>Be aware that if you try to add a RATE_BASED rule to a web ACL without setting the rule type when first creating the rule, the <a>UpdateWebACL</a> request will fail because the request tries to add a REGULAR rule (the default rule type) with the specified ID, which does not exist. </p> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595212 = newJObject()
  if body != nil:
    body_595212 = body
  result = call_595211.call(nil, nil, nil, nil, body_595212)

var updateWebACL* = Call_UpdateWebACL_595198(name: "updateWebACL",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateWebACL",
    validator: validate_UpdateWebACL_595199, base: "/", url: url_UpdateWebACL_595200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateXssMatchSet_595213 = ref object of OpenApiRestCall_593437
proc url_UpdateXssMatchSet_595215(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateXssMatchSet_595214(path: JsonNode; query: JsonNode;
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
  var valid_595216 = header.getOrDefault("X-Amz-Date")
  valid_595216 = validateParameter(valid_595216, JString, required = false,
                                 default = nil)
  if valid_595216 != nil:
    section.add "X-Amz-Date", valid_595216
  var valid_595217 = header.getOrDefault("X-Amz-Security-Token")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Security-Token", valid_595217
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_595218 = header.getOrDefault("X-Amz-Target")
  valid_595218 = validateParameter(valid_595218, JString, required = true, default = newJString(
      "AWSWAF_Regional_20161128.UpdateXssMatchSet"))
  if valid_595218 != nil:
    section.add "X-Amz-Target", valid_595218
  var valid_595219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "X-Amz-Content-Sha256", valid_595219
  var valid_595220 = header.getOrDefault("X-Amz-Algorithm")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-Algorithm", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Signature")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Signature", valid_595221
  var valid_595222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595222 = validateParameter(valid_595222, JString, required = false,
                                 default = nil)
  if valid_595222 != nil:
    section.add "X-Amz-SignedHeaders", valid_595222
  var valid_595223 = header.getOrDefault("X-Amz-Credential")
  valid_595223 = validateParameter(valid_595223, JString, required = false,
                                 default = nil)
  if valid_595223 != nil:
    section.add "X-Amz-Credential", valid_595223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_595225: Call_UpdateXssMatchSet_595213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Inserts or deletes <a>XssMatchTuple</a> objects (filters) in an <a>XssMatchSet</a>. For each <code>XssMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change an <code>XssMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for cross-site scripting attacks.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>XssMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain cross-site scripting attacks in the request body and you want to block the requests, you can create an <code>XssMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateXssMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateXssMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ## 
  let valid = call_595225.validator(path, query, header, formData, body)
  let scheme = call_595225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595225.url(scheme.get, call_595225.host, call_595225.base,
                         call_595225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595225, url, valid)

proc call*(call_595226: Call_UpdateXssMatchSet_595213; body: JsonNode): Recallable =
  ## updateXssMatchSet
  ## <p>Inserts or deletes <a>XssMatchTuple</a> objects (filters) in an <a>XssMatchSet</a>. For each <code>XssMatchTuple</code> object, you specify the following values:</p> <ul> <li> <p> <code>Action</code>: Whether to insert the object into or delete the object from the array. To change an <code>XssMatchTuple</code>, you delete the existing object and add a new one.</p> </li> <li> <p> <code>FieldToMatch</code>: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter.</p> </li> <li> <p> <code>TextTransformation</code>: Which text transformation, if any, to perform on the web request before inspecting the request for cross-site scripting attacks.</p> <p>You can only specify a single type of TextTransformation.</p> </li> </ul> <p>You use <code>XssMatchSet</code> objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain cross-site scripting attacks in the request body and you want to block the requests, you can create an <code>XssMatchSet</code> with the applicable settings, and then configure AWS WAF to block the requests. </p> <p>To create and configure an <code>XssMatchSet</code>, perform the following steps:</p> <ol> <li> <p>Submit a <a>CreateXssMatchSet</a> request.</p> </li> <li> <p>Use <a>GetChangeToken</a> to get the change token that you provide in the <code>ChangeToken</code> parameter of an <a>UpdateIPSet</a> request.</p> </li> <li> <p>Submit an <code>UpdateXssMatchSet</code> request to specify the parts of web requests that you want AWS WAF to inspect for cross-site scripting attacks.</p> </li> </ol> <p>For more information about how to use the AWS WAF API to allow or block HTTP requests, see the <a href="https://docs.aws.amazon.com/waf/latest/developerguide/">AWS WAF Developer Guide</a>.</p>
  ##   body: JObject (required)
  var body_595227 = newJObject()
  if body != nil:
    body_595227 = body
  result = call_595226.call(nil, nil, nil, nil, body_595227)

var updateXssMatchSet* = Call_UpdateXssMatchSet_595213(name: "updateXssMatchSet",
    meth: HttpMethod.HttpPost, host: "waf-regional.amazonaws.com",
    route: "/#X-Amz-Target=AWSWAF_Regional_20161128.UpdateXssMatchSet",
    validator: validate_UpdateXssMatchSet_595214, base: "/",
    url: url_UpdateXssMatchSet_595215, schemes: {Scheme.Https, Scheme.Http})
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
